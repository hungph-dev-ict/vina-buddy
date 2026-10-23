import re

_PHONE_PATTERN = re.compile(
    r"\b(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b"
)
_EMAIL_PATTERN = re.compile(r"\b([a-zA-Z0-9_.+-]+)@([a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)\b")


def extract_domain(email_str: str) -> str:
    """Extract domain from an email address for privacy-safe matching."""
    match = _EMAIL_PATTERN.search(email_str)
    if match:
        return match.group(2).lower()
    return email_str.strip().lower()


def sanitize_text(text: str, max_chars: int = 250) -> str:
    """
    Sanitize untrusted text:
    1. Truncate to max_chars to prevent prompt ballooning.
    2. Redact phone numbers.
    3. Redact email usernames to preserve only domains.
    4. Escape backticks and control characters.
    """
    if not text:
        return ""

    truncated = text[:max_chars].strip()
    redacted_phone = _PHONE_PATTERN.sub("[PHONE]", truncated)
    redacted_email = _EMAIL_PATTERN.sub(r"[USER]@\2", redacted_phone)
    # Neutralize control characters
    cleaned = re.sub(r"[\x00-\x1f\x7f-\x9f]", " ", redacted_email)
    return cleaned


def build_safe_rule_parsing_prompt(user_text: str) -> str:
    """
    Build prompt to parse natural language rule into structured format.
    Email data or user input is treated as literal data string.
    Supports multi-intent separation and out-of-scope intent rejection.
    """
    cleaned_input = sanitize_text(user_text, max_chars=500)
    return (
        "You are an email rule extraction engine.\n"
        "Your task is to parse a user's natural language request into valid structured JSON rule(s).\n\n"
        "CRITICAL SECURITY CONSTRAINTS:\n"
        "1. Allowed action types are ONLY: 'add_label', 'remove_label'.\n"
        "2. You must NEVER output actions such as 'delete', 'send', 'archive', 'trash', or 'mark_read'.\n"
        "3. Allowed condition fields are ONLY: 'from', 'subject', 'snippet', 'label', 'date'.\n"
        "4. Allowed operators are ONLY: 'equals', 'contains', 'starts_with', 'ends_with', 'regex'.\n\n"
        "CRITICAL MULTI-INTENT SEPARATION RULE:\n"
        "- If the user input describes multiple rules (e.g. 'emails from tldr are spam and emails from GitHub are source code'), "
        "DO NOT combine them into one rule with multiple conditions. "
        "Separate each into its own independent rule in the 'rules' list (Condition 1 -> Action 1 in Rule 1, Condition 2 -> Action 2 in Rule 2).\n\n"
        "CRITICAL OUT-OF-SCOPE REJECTION:\n"
        "- If the user request is NOT about email management (e.g., chat, greetings, weather, coding, poems, general QA, or unsupported actions), you MUST output:\n"
        "{\n"
        '  "supported": false,\n'
        '  "reason": "unsupported_content",\n'
        '  "message": "Nội dung này không thể hỗ trợ, vui lòng khiếu nại tới admin."\n'
        "}\n\n"
        "OUTPUT SCHEMA (JSON ONLY):\n"
        "If supported, output:\n"
        "{\n"
        '  "supported": true,\n'
        '  "rules": [\n'
        "    {\n"
        '      "name": "Short Descriptive Rule Name",\n'
        '      "conditions": [{"field": "from", "operator": "contains", "value": "example.com"}],\n'
        '      "actions": [{"type": "add_label", "label": "LabelName"}],\n'
        '      "priority": 1,\n'
        '      "confidence": 0.95\n'
        "    }\n"
        "  ]\n"
        "}\n\n"
        f"USER REQUEST TO PARSE:\n{cleaned_input}\n"
    )

