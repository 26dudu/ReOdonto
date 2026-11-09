from datetime import datetime, timezone


def agora_utc() -> datetime:
    return datetime.now(timezone.utc)


class OtpMixin:
    def esta_expirado(self) -> bool:
        expira = self.expira_em
        if expira.tzinfo is None:
            expira = expira.replace(tzinfo=timezone.utc)
        return agora_utc() > expira

    def esta_valido(self) -> bool:
        return not self.usado and not self.esta_expirado()
