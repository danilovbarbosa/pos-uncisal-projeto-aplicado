"""
Testes do fluxo de autenticação e das mitigações OWASP Top 10:2025.
"""

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse

User = get_user_model()


class AuthFlowTests(TestCase):
    def setUp(self):
        self.username = "aluno"
        self.password = "SenhaForte2025!"
        self.user = User.objects.create_user(
            username=self.username, password=self.password
        )
        self.login_url = reverse("accounts:login")
        self.dashboard_url = reverse("accounts:dashboard")
        self.logout_url = reverse("accounts:logout")

    def test_dashboard_exige_login(self):
        """A01: página interna redireciona anônimos para o login."""
        response = self.client.get(self.dashboard_url)
        self.assertEqual(response.status_code, 302)
        self.assertIn(self.login_url, response.url)

    def test_login_com_credenciais_validas(self):
        response = self.client.post(
            self.login_url,
            {"username": self.username, "password": self.password},
            follow=True,
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.context["user"].is_authenticated)

    def test_login_com_senha_invalida_falha(self):
        """A07: mensagem genérica e sem autenticar."""
        response = self.client.post(
            self.login_url,
            {"username": self.username, "password": "errada"},
        )
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.context["user"].is_authenticated)

    def test_acesso_ao_dashboard_apos_login(self):
        self.client.login(username=self.username, password=self.password)
        response = self.client.get(self.dashboard_url)
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, self.username)

    def test_logout_encerra_sessao(self):
        self.client.login(username=self.username, password=self.password)
        response = self.client.post(self.logout_url, follow=True)
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.context["user"].is_authenticated)

    def test_logout_via_get_nao_encerra_sessao(self):
        """Logout só por POST (evita logout forçado via link/imagem)."""
        self.client.login(username=self.username, password=self.password)
        response = self.client.get(self.logout_url)
        self.assertEqual(response.status_code, 405)  # Method Not Allowed


class SecurityMitigationTests(TestCase):
    def setUp(self):
        self.login_url = reverse("accounts:login")

    def test_csrf_token_presente_no_form(self):
        """A01: o formulário de login inclui o token CSRF."""
        response = self.client.get(self.login_url)
        self.assertContains(response, "csrfmiddlewaretoken")

    def test_post_sem_csrf_e_bloqueado(self):
        """A01: POST sem token CSRF é rejeitado (403)."""
        csrf_client = self.client_class(enforce_csrf_checks=True)
        response = csrf_client.post(
            self.login_url, {"username": "x", "password": "y"}
        )
        self.assertEqual(response.status_code, 403)

    def test_username_com_caracteres_invalidos_e_rejeitado(self):
        """A05: entrada com caracteres fora da allowlist é barrada."""
        response = self.client.post(
            self.login_url,
            {"username": "<script>alert(1)</script>", "password": "qualquer"},
        )
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.context["user"].is_authenticated)

    def test_senha_armazenada_com_argon2(self):
        """A04: senhas são hasheadas com Argon2, nunca em texto puro."""
        user = User.objects.create_user(username="teste", password="SenhaForte2025!")
        self.assertTrue(user.password.startswith("argon2"))
        self.assertNotIn("SenhaForte2025!", user.password)

    def test_cabecalhos_de_seguranca(self):
        """A02: cabeçalhos de segurança presentes na resposta."""
        response = self.client.get(self.login_url)
        self.assertEqual(response.headers.get("X-Content-Type-Options"), "nosniff")
        self.assertEqual(response.headers.get("X-Frame-Options"), "DENY")
