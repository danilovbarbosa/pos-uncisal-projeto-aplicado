"""Formulário de autenticação com sanitização/normalização e logging."""

import logging

from django.contrib.auth.forms import AuthenticationForm
from django.core.exceptions import ValidationError

security_logger = logging.getLogger("accounts.security")


class SecureLoginForm(AuthenticationForm):
    """
    Estende o AuthenticationForm padrão do Django.

    OWASP A05:2025 (Injection/XSS): o campo de usuário é normalizado e
    validado com uma lista de caracteres permitidos, evitando payloads
    inesperados. O escape de saída continua a cargo do template engine.

    OWASP A07:2025 (Authentication Failures): mensagens de erro genéricas
    (não revelam se o usuário existe) e registro de tentativas falhas.
    """

    # Comprimento máximo defensivo para evitar entradas absurdamente grandes.
    MAX_USERNAME_LENGTH = 150

    def clean_username(self):
        username = self.cleaned_data.get("username", "")
        # Normaliza espaços nas bordas.
        username = username.strip()

        if len(username) > self.MAX_USERNAME_LENGTH:
            raise ValidationError("Nome de usuário inválido.")

        # Permite apenas caracteres razoáveis para um login (letras, dígitos,
        # e os símbolos @ . + - _ que o Django usa em usernames/e-mails).
        allowed = set(
            "abcdefghijklmnopqrstuvwxyz"
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            "0123456789@.+-_"
        )
        if any(char not in allowed for char in username):
            raise ValidationError("Nome de usuário contém caracteres não permitidos.")

        return username

    def confirm_login_allowed(self, user):
        # Bloqueia contas inativas com mensagem genérica.
        super().confirm_login_allowed(user)

    def get_invalid_login_error(self):
        # Registra a tentativa falha sem vazar qual campo estava errado.
        username = self.cleaned_data.get("username") or self.data.get("username", "")
        security_logger.warning(
            "Falha de autenticação para usuário='%s'", username[:64]
        )
        return super().get_invalid_login_error()
