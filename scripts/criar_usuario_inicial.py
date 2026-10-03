#!/usr/bin/env python3
"""Gera SQL para a primeira conta; perguntas vão ao terminal, SQL à saída padrão."""
import base64
import getpass
import hashlib
import re
import secrets
import sys


def literal(valor):
    return "'" + valor.replace("'", "''") + "'"


def main():
    print("Nome: ", end="", file=sys.stderr, flush=True)
    nome = input().strip()
    print("E-mail: ", end="", file=sys.stderr, flush=True)
    email = input().strip().lower()
    senha = getpass.getpass("Senha (12 a 128 caracteres): ")
    confirmacao = getpass.getpass("Confirme a senha: ")
    if not 1 <= len(nome) <= 100 or len(email) > 254 or not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email):
        raise SystemExit("Nome ou e-mail inválido.")
    if not 12 <= len(senha.strip()) <= 128 or senha != confirmacao:
        raise SystemExit("Senha inválida ou confirmação diferente.")
    salt = base64.b64encode(secrets.token_bytes(32)).decode()
    derivado = hashlib.pbkdf2_hmac("sha256", senha.encode(), salt.encode(), 600000, dklen=32)
    senha_hash = "pbkdf2-sha256$600000$" + salt + "$" + base64.b64encode(derivado).decode()
    print("BEGIN;\nSET LOCAL standard_conforming_strings = on;\nLOCK TABLE cmscondominio.tb_usuarios IN EXCLUSIVE MODE;")
    print("INSERT INTO cmscondominio.tb_usuarios (nm_usuario, tx_email, tx_senha_hash)")
    print("SELECT " + ", ".join(map(literal, [nome, email, senha_hash])))
    print("WHERE NOT EXISTS (SELECT 1 FROM cmscondominio.tb_usuarios);\nCOMMIT;")


if __name__ == "__main__":
    main()
