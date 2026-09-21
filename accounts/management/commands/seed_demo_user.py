"""
Cria (ou atualiza) um usuário de demonstração de forma idempotente.

As credenciais são lidas de variáveis de ambiente para não ficarem
fixas no código (OWASP A02:2025 / A07:2025). Valores padrão existem
apenas para facilitar a avaliação local do protótipo.
"""

import os

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Cria/atualiza o usuário de demonstração para o protótipo."

    def handle(self, *args, **options):
        User = get_user_model()

        username = os.environ.get("DEMO_USERNAME", "aluno")
        email = os.environ.get("DEMO_EMAIL", "aluno@example.com")
        password = os.environ.get("DEMO_PASSWORD", "SenhaForte2025!")

        user, created = User.objects.get_or_create(
            username=username,
            defaults={"email": email},
        )
        user.email = email
        user.set_password(password)  # armazenada com hash Argon2
        user.is_active = True
        user.save()

        if created:
            self.stdout.write(
                self.style.SUCCESS(f"Usuário '{username}' criado com sucesso.")
            )
        else:
            self.stdout.write(
                self.style.WARNING(f"Usuário '{username}' já existia; senha redefinida.")
            )
        self.stdout.write("Use essas credenciais para testar o login do protótipo.")
