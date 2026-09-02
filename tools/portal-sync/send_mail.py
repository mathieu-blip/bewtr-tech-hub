#!/usr/bin/env python3
"""Envoie le compte rendu du portail par courrier.

Les réglages viennent de l'environnement, pour que rien de secret ne traîne
dans le dépôt :

    MAIL_HOST      le serveur d'envoi          (ex. smtp.gmail.com)
    MAIL_PORT      son port                    (465 par défaut, en SSL)
    MAIL_USER      le compte qui envoie
    MAIL_PASSWORD  son mot de passe d'application
    MAIL_FROM      l'expéditeur affiché        (MAIL_USER par défaut)
    MAIL_TO        le ou les destinataires, séparés par des virgules

    python3 tools/portal-sync/send_mail.py --subject "…" --body rapport.md
"""

import argparse
import os
import smtplib
import sys
from email.message import EmailMessage


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--subject", required=True)
    parser.add_argument("--body", required=True, help="le fichier à envoyer")
    parser.add_argument("--link", help="l'adresse de la pull request, à ajouter")
    args = parser.parse_args()

    host = os.environ.get("MAIL_HOST")
    user = os.environ.get("MAIL_USER")
    password = os.environ.get("MAIL_PASSWORD")
    to = os.environ.get("MAIL_TO")
    if not (host and user and password and to):
        print("réglages d'envoi absents : pas de courrier", file=sys.stderr)
        return 0

    with open(args.body, encoding="utf-8") as f:
        text = f.read()
    if args.link:
        text += "\n\nLa proposition à relire : %s\n" % args.link

    message = EmailMessage()
    message["Subject"] = args.subject
    message["From"] = os.environ.get("MAIL_FROM") or user
    message["To"] = to
    message.set_content(text)

    port = int(os.environ.get("MAIL_PORT") or 465)
    if port == 465:
        server = smtplib.SMTP_SSL(host, port, timeout=60)
    else:
        server = smtplib.SMTP(host, port, timeout=60)
        server.starttls()
    with server:
        server.login(user, password)
        server.send_message(message)
    print("courrier envoyé à %s" % to)
    return 0


if __name__ == "__main__":
    sys.exit(main())
