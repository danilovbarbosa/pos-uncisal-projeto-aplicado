"""Views de autenticação e área interna protegida."""

import logging

from django.contrib.auth import views as auth_views
from django.contrib.auth.decorators import login_required
from django.shortcuts import render
from django.utils.decorators import method_decorator
from django.views.decorators.debug import sensitive_post_parameters

from .forms import SecureLoginForm

security_logger = logging.getLogger("accounts.security")


class LoginView(auth_views.LoginView):
    """
    Tela de login.

    - OWASP A01:2025: proteção CSRF (herdada, o template usa {% csrf_token %}).
    - OWASP A07:2025: renova o ID de sessão no login (feito pelo Django),
      usa form com mensagens genéricas e registra logins bem-sucedidos.
    """

    template_name = "accounts/login.html"
    authentication_form = SecureLoginForm
    redirect_authenticated_user = True

    # Marca a senha como parâmetro sensível para não vazar em relatórios de erro.
    @method_decorator(sensitive_post_parameters("password"))
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)

    def form_valid(self, form):
        response = super().form_valid(form)
        security_logger.info(
            "Login bem-sucedido para usuário='%s'", self.request.user.get_username()
        )
        return response


class LogoutView(auth_views.LogoutView):
    """
    Logout funcional.

    - Só aceita POST (o Django exige POST para logout), evitando logout
      forçado via link/imagem (CSRF de logout).
    - Encerra a sessão e redireciona para LOGOUT_REDIRECT_URL.
    """

    def post(self, request, *args, **kwargs):
        if request.user.is_authenticated:
            security_logger.info(
                "Logout do usuário='%s'", request.user.get_username()
            )
        return super().post(request, *args, **kwargs)


@login_required
def dashboard(request):
    """
    Página interna acessível apenas após autenticação.

    - OWASP A01:2025 (Broken Access Control): o decorador @login_required
      redireciona usuários não autenticados para a tela de login.
    """
    return render(request, "accounts/dashboard.html", {"usuario": request.user})
