#!/usr/bin/env python3
"""
OrangeBox - filtro MIME para imapsync.

Lee un mensaje RFC822 por STDIN y lo entrega por STDOUT.
Elimina solamente attachments cuyo tamaño decodificado sea mayor
que el umbral configurado.

Regla de detección, alineada con zimbra_attachment_scan.py:
  - Content-Disposition: attachment
  - o filename/name presente

STDOUT contiene solamente el mensaje resultante.
Diagnóstico y auditoría van por STDERR/CSV.
"""

from __future__ import print_function

import argparse
import csv
import datetime
import fcntl
import io
import os
import select
import sys

from email import policy
from email.generator import BytesGenerator
from email.parser import BytesParser


DEFAULT_THRESHOLD_MIB = 5.0


def filename_of(part):
    try:
        return part.get_filename() or ""
    except Exception:
        return ""


def attachment_info(part):
    disposition_header = part.get("Content-Disposition", "") or ""
    disposition = disposition_header.split(";", 1)[0].strip().lower()

    filename = ""
    try:
        filename = (
            part.get_param("filename", header="content-disposition")
            or part.get_param("name", header="content-type")
            or ""
        )
    except Exception:
        pass

    content_id = part.get("Content-ID", "") or ""
    mime_type = part.get_content_type().lower()

    is_attachment = disposition == "attachment" or bool(filename)
    is_inline_image = (
        mime_type.startswith("image/")
        and (
            disposition == "inline"
            or bool(content_id)
        )
    )

    return (
        is_attachment,
        is_inline_image,
        filename_of(part),
        disposition,
    )


def part_size(part):
    try:
        payload = part.get_payload(decode=True)
    except Exception as exc:
        raise ValueError("no pude decodificar el payload: %s" % exc)

    if isinstance(payload, bytes):
        return len(payload)

    # El scanner trata message/rfc822 como una hoja/attachment.
    if part.get_content_type().lower() == "message/rfc822":
        nested = part.get_payload()
        if isinstance(nested, list):
            total = 0
            for message in nested:
                try:
                    total += len(message.as_bytes(policy=policy.SMTP))
                except Exception as exc:
                    raise ValueError(
                        "no pude serializar message/rfc822: %s" % exc
                    )
            return total

    raise ValueError(
        "no pude determinar el tamaño de %s" % part.get_content_type()
    )


def is_container(part):
    return (
        part.is_multipart()
        and part.get_content_type().lower() != "message/rfc822"
    )


def filter_part(
    part,
    part_number,
    threshold_bytes,
    inline_threshold_bytes,
    removals,
):
    """Devuelve (keep, changed)."""
    if is_container(part):
        payload = part.get_payload()
        if not isinstance(payload, list):
            raise ValueError(
                "multipart con payload inválido en %s" % part_number
            )

        kept = []
        changed = False

        for index, child in enumerate(payload, 1):
            keep, child_changed = filter_part(
                child,
                "%s.%d" % (part_number, index),
                threshold_bytes,
                inline_threshold_bytes,
                removals,
            )
            changed = changed or child_changed
            if keep:
                kept.append(child)

        if changed:
            part.set_payload(kept)

        return True, changed

    is_attachment, is_inline_image, filename, disposition = attachment_info(part)

    size = part_size(part)

    if is_inline_image and inline_threshold_bytes > 0:
        # Las imágenes inline/CID tienen un umbral independiente para poder
        # detectar firmas HTML y recursos embebidos sin bajar el límite general
        # de attachments.
        if size > inline_threshold_bytes:
            removals.append(
                {
                    "part": part_number,
                    "filename": filename,
                    "mime_type": part.get_content_type(),
                    "disposition": disposition,
                    "size_bytes": size,
                    "reason": "inline_image",
                }
            )
            return False, True

    if not is_attachment:
        return True, False

    # La política general sigue siendo estrictamente "mayor al umbral".
    if size <= threshold_bytes:
        return True, False

    removals.append(
        {
            "part": part_number,
            "filename": filename,
            "mime_type": part.get_content_type(),
            "disposition": disposition,
            "size_bytes": size,
            "reason": "attachment",
        }
    )

    return False, True


def write_audit(path, message, removals, threshold_bytes):
    if not path or not removals:
        return

    directory = os.path.dirname(os.path.abspath(path))
    if directory and not os.path.isdir(directory):
        os.makedirs(directory)

    exists = os.path.exists(path)

    with open(path, "a", encoding="utf-8", newline="") as fh:
        fcntl.flock(fh.fileno(), fcntl.LOCK_EX)
        try:
            writer = csv.writer(fh)
            if not exists or os.path.getsize(path) == 0:
                writer.writerow([
                    "timestamp_utc",
                    "message_id",
                    "subject",
                    "part",
                    "mime_type",
                    "filename",
                    "disposition",
                    "size_bytes",
                    "size_mib",
                    "threshold_bytes",
                    "action",
                ])

            timestamp = (
                datetime.datetime.utcnow()
                .replace(microsecond=0)
                .isoformat()
                + "Z"
            )

            for item in removals:
                writer.writerow([
                    timestamp,
                    str(message.get("Message-ID", "")),
                    str(message.get("Subject", "")),
                    item["part"],
                    item["mime_type"],
                    item["filename"],
                    item["disposition"],
                    item["size_bytes"],
                    "%.6f" % (item["size_bytes"] / 1048576.0),
                    threshold_bytes,
                    "removed",
                ])
            fh.flush()
        finally:
            fcntl.flock(fh.fileno(), fcntl.LOCK_UN)


def transform(
    raw_message,
    threshold_bytes,
    inline_threshold_bytes,
    log_path,
    report_only=False,
):
    try:
        message = BytesParser(policy=policy.default).parsebytes(raw_message)
    except Exception as exc:
        raise ValueError("MIME parse error: %s" % exc)

    removals = []

    # La raíz nunca se elimina.
    if is_container(message):
        payload = message.get_payload()
        if not isinstance(payload, list):
            raise ValueError("mensaje multipart con payload inválido")

        kept = []
        changed = False

        for index, child in enumerate(payload, 1):
            keep, child_changed = filter_part(
                child,
                str(index),
                threshold_bytes,
                inline_threshold_bytes,
                removals,
            )
            changed = changed or child_changed
            if keep:
                kept.append(child)

        if changed:
            message.set_payload(kept)

    if not removals:
        # Máxima fidelidad: si no hay nada que quitar, salen los bytes
        # originales, sin parsear/reserializar el mensaje.
        return raw_message, removals

    write_audit(log_path, message, removals, threshold_bytes)

    if report_only:
        return raw_message, removals

    output = io.BytesIO()
    BytesGenerator(
        output,
        policy=policy.SMTP,
        mangle_from_=False,
        maxheaderlen=None,
    ).flatten(message, unixfrom=False)

    return output.getvalue(), removals


def write_all_stdout(data):
    fd = sys.stdout.fileno()
    offset = 0

    while offset < len(data):
        try:
            written = os.write(fd, data[offset:])
            if written == 0:
                raise IOError("STDOUT cerró el descriptor")
            offset += written
        except BlockingIOError:
            select.select([], [fd], [])


def main():
    parser = argparse.ArgumentParser(
        description="Elimina attachments MIME mayores al umbral para imapsync."
    )
    parser.add_argument(
        "--threshold-mib",
        type=float,
        default=float(
            os.environ.get(
                "ORANGEBOX_ATTACHMENT_THRESHOLD_MIB",
                DEFAULT_THRESHOLD_MIB,
            )
        ),
    )
    parser.add_argument(
        "--log",
        default=os.environ.get("ORANGEBOX_IMAPSYNC_FILTER_LOG", ""),
        help="CSV de auditoría; vacío para no registrar archivo.",
    )
    parser.add_argument(
        "--inline-threshold-mib",
        type=float,
        default=0.0,
        help=(
            "Umbral independiente para imágenes inline/CID. "
            "0 desactiva esta regla."
        ),
    )
    parser.add_argument(
        "--report-only",
        action="store_true",
        help="Reporta coincidencias pero entrega el mensaje original.",
    )

    args = parser.parse_args()

    if args.threshold_mib <= 0:
        print(
            "ERROR: --threshold-mib debe ser mayor que cero.",
            file=sys.stderr,
        )
        return 2

    if args.inline_threshold_mib < 0:
        print(
            "ERROR: --inline-threshold-mib no puede ser negativo.",
            file=sys.stderr,
        )
        return 2

    threshold_bytes = int(args.threshold_mib * 1024 * 1024)
    inline_threshold_bytes = int(args.inline_threshold_mib * 1024 * 1024)
    raw_message = sys.stdin.buffer.read()

    if not raw_message:
        print("ERROR: STDIN está vacío.", file=sys.stderr)
        return 2

    try:
        output, removals = transform(
            raw_message,
            threshold_bytes,
            inline_threshold_bytes,
            args.log,
            report_only=args.report_only,
        )
    except Exception as exc:
        # Fail closed.
        print("ERROR: filtro MIME: %s" % exc, file=sys.stderr)
        return 1

    if removals:
        print(
            "[OrangeBox] %d attachment(s) > %d bytes"
            % (len(removals), threshold_bytes),
            file=sys.stderr,
        )
        for item in removals:
            action = (
                "report-inline-image"
                if item.get("reason") == "inline_image" and args.report_only
                else "removed"
            )
            print(
                "[OrangeBox] %s part=%s file=%s size=%d mime=%s"
                % (
                    action,
                    item["part"],
                    item["filename"] or "<sin nombre>",
                    item["size_bytes"],
                    item["mime_type"],
                ),
                file=sys.stderr,
            )

    write_all_stdout(output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
