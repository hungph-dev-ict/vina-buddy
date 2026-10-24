from fastapi import APIRouter, HTTPException, Request, status

from app.schemas.auth import (
    AuthSessionResponse,
    GoogleAuthRequest,
    RefreshTokenRequest,
    RevokeResponse,
)
from app.services.auth_service import (
    AuthExpiredError,
    AuthService,
    OAuthDenialError,
)

router = APIRouter(tags=["Auth"])

# Singleton auth service instance
auth_service = AuthService()


@router.post(
    "/auth/google",
    response_model=AuthSessionResponse,
    summary="Exchange Google authorization code for session",
)
async def exchange_google_code(request: GoogleAuthRequest) -> AuthSessionResponse:
    try:
        session_token, email, expires_at = await auth_service.exchange_google_code(
            auth_code=request.auth_code,
            redirect_uri=request.redirect_uri,
        )
        return AuthSessionResponse(
            session_token=session_token,
            email=email,
            expires_at=expires_at,
        )
    except OAuthDenialError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "OAUTH_DENIED", "message": str(exc)},
        ) from exc


@router.get(
    "/auth/google/url",
    summary="Get Google OAuth 2.0 authorization URL for browser login",
)
async def get_google_auth_url(
    server_host: str | None = None,
    redirect_uri: str | None = None,
):
    from app.config import settings

    if not redirect_uri:
        if settings.GOOGLE_REDIRECT_URI and "callback" in settings.GOOGLE_REDIRECT_URI:
            redirect_uri = settings.GOOGLE_REDIRECT_URI
        else:
            host = server_host or f"{settings.HOST}:{settings.PORT}"
            if host.startswith("0.0.0.0"):
                host = "192.168.1.109:8000"
            scheme = "https" if "ngrok" in host or "trycloudflare" in host else "http"
            redirect_uri = f"{scheme}://{host}/api/v1/auth/google/callback"


    res = auth_service.get_google_auth_url(redirect_uri=redirect_uri)
    return res


@router.post(
    "/auth/google/config",
    summary="Save Google OAuth 2.0 Client ID and Secret",
)
async def set_google_config(request: dict):
    client_id = request.get("client_id", "").strip()
    client_secret = request.get("client_secret", "").strip()
    if not client_id or not client_secret:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INVALID_CONFIG", "message": "Client ID and Client Secret are required."},
        )
    auth_service.set_google_credentials(client_id, client_secret)
    return {"status": "saved", "client_id": client_id}


@router.get(
    "/auth/google/callback",
    summary="Google OAuth 2.0 Callback handler for web browser",
)
async def google_callback(
    request: Request,
    code: str | None = None,
    state: str | None = None,
    error: str | None = None,
):
    from fastapi.responses import HTMLResponse

    if error or not code:
        err_msg = error or "Authorization code missing."
        return HTMLResponse(
            content=f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đăng nhập Google thất bại</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #0F172A; color: white; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }}
        .card {{ background: #1E293B; padding: 32px; border-radius: 20px; text-align: center; max-width: 420px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }}
        h2 {{ color: #EF4444; margin-top: 0; }}
        p {{ color: #94A3B8; font-size: 14px; line-height: 1.5; }}
    </style>
</head>
<body>
    <div class="card">
        <h2>❌ Đăng nhập bị hủy hoặc lỗi</h2>
        <p>{err_msg}</p>
        <p>Vui lòng đóng trang này và thử lại trong ứng dụng Vina Buddy.</p>
    </div>
</body>
</html>""",
            status_code=400,
        )

    try:
        from app.config import settings
        if settings.GOOGLE_REDIRECT_URI and "callback" in settings.GOOGLE_REDIRECT_URI:
            redirect_uri = settings.GOOGLE_REDIRECT_URI
        else:
            redirect_uri = str(request.url).split("?")[0]

        session_token, user_email, _ = await auth_service.exchange_google_code(
            auth_code=code,
            redirect_uri=redirect_uri,
            state=state,
        )

        deep_link = f"vinabuddy://auth?session_token={session_token}&email={user_email}"

        html_content = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đăng nhập thành công — Vina Buddy</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #1E1B4B 0%, #0F172A 100%);
            color: #F8FAFC;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            padding: 16px;
            box-sizing: border-box;
        }}
        .card {{
            background: #1E293B;
            border: 1px solid #334155;
            padding: 36px 28px;
            border-radius: 24px;
            text-align: center;
            max-width: 440px;
            width: 100%;
            box-shadow: 0 20px 40px rgba(0,0,0,0.6);
        }}
        .icon {{
            font-size: 54px;
            margin-bottom: 16px;
        }}
        h2 {{
            color: #38BDF8;
            font-size: 22px;
            margin: 0 0 8px 0;
            font-weight: 800;
        }}
        .email {{
            background: #0F172A;
            color: #A5B4FC;
            font-weight: 600;
            padding: 8px 14px;
            border-radius: 8px;
            display: inline-block;
            margin: 12px 0 16px 0;
            font-size: 14px;
            word-break: break-all;
            border: 1px solid #312E81;
        }}
        p {{
            color: #94A3B8;
            font-size: 14px;
            line-height: 1.6;
            margin: 8px 0;
        }}
        .btn {{
            display: inline-block;
            background: #6366F1;
            color: white;
            text-decoration: none;
            padding: 14px 28px;
            border-radius: 14px;
            font-weight: 700;
            margin-top: 20px;
            font-size: 15px;
            transition: background 0.2s;
            box-shadow: 0 4px 14px rgba(99, 102, 241, 0.4);
        }}
        .btn:hover {{
            background: #4F46E5;
        }}
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">🎉</div>
        <h2>Đăng nhập Google thành công!</h2>
        <div class="email">{user_email}</div>
        <p>Tài khoản Gmail của bạn đã được kết nối an toàn với AI Vina Buddy.</p>
        <p>Ứng dụng Vina Buddy trên điện thoại sẽ tự động mở lại ngay bây giờ.</p>
        <a href="{deep_link}" class="btn">Mở lại Vina Buddy</a>
    </div>
    <script>
        setTimeout(function() {{
            window.location.href = "{deep_link}";
        }}, 600);
    </script>
</body>
</html>"""
        return HTMLResponse(content=html_content)

    except Exception as exc:
        return HTMLResponse(
            content=f"""<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Lỗi xác thực</title></head>
<body style="font-family: sans-serif; background: #0F172A; color: white; padding: 40px; text-align: center;">
    <h2>❌ Xác thực mã Google thất bại</h2>
    <p style="color: #EF4444;">{str(exc)}</p>
    <p>Vui lòng thử đăng nhập lại từ ứng dụng.</p>
</body>
</html>""",
            status_code=400,
        )


@router.get(
    "/auth/google/poll",
    summary="Poll Google OAuth login status for mobile app",
)
async def poll_google_auth(state: str):
    return auth_service.poll_pending_auth(state)



@router.post(
    "/auth/refresh",
    response_model=AuthSessionResponse,
    summary="Refresh session token",
)
async def refresh_session(request: RefreshTokenRequest) -> AuthSessionResponse:
    try:
        session = auth_service.get_valid_session(request.session_token)
        token, expires_at = auth_service.refresh_session(request.session_token)
        return AuthSessionResponse(
            session_token=token,
            email=session.email,
            expires_at=expires_at,
        )
    except AuthExpiredError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "AUTH_EXPIRED", "message": str(exc)},
        ) from exc


@router.post(
    "/auth/revoke",
    response_model=RevokeResponse,
    summary="Revoke session and disconnect Gmail",
)
async def revoke_session(request: RefreshTokenRequest) -> RevokeResponse:
    auth_service.revoke_session(request.session_token)
    return RevokeResponse(status="revoked")
