import re
from typing import Any, Dict, Optional, Tuple, Union

from app.agents.base_agent import BaseAgent
from app.agents.models import IntentScopeResult
from app.schemas.reminders import ReminderCreate, ReminderSchedule
from app.services.reminders_service import get_reminders_service


class ThayCungAgent(BaseAgent):
    """
    Specialized agent for Vietnamese traditional workplace rituals and lunar calendar.
    """

    def _parse_lunar_date(self, text: str) -> Optional[Tuple[int, Optional[int], str]]:
        lower = text.lower()
        # Month 12: "tháng chạp", "tháng 12"
        m_chap = re.search(r"(?:ngày|mùng)?\s*(\d{1,2})\s+tháng\s+(?:chạp|mười hai)", lower)
        if m_chap:
            d = int(m_chap.group(1))
            if 1 <= d <= 31:
                return (d, 12, f"{d} tháng Chạp")
        # Month 1: "tháng giêng", "tháng 1"
        m_gieng = re.search(r"(?:ngày|mùng)?\s*(\d{1,2})\s+tháng\s+(?:giêng|một)", lower)
        if m_gieng:
            d = int(m_gieng.group(1))
            if 1 <= d <= 31:
                return (d, 1, f"{d} tháng Giêng")
        # "ngày 15 tháng 3"
        m_thang = re.search(r"(?:ngày|mùng)\s*(\d{1,2})\s+tháng\s*(\d{1,2})", lower)
        if m_thang:
            d, m = int(m_thang.group(1)), int(m_thang.group(2))
            if 1 <= d <= 31 and 1 <= m <= 12:
                return (d, m, f"{d}/{m}")
        # Slash/dash format: e.g. 10/24, 24/10, 15/3, 15-3
        m_slash = re.search(r"(?:ngày|mùng)?\s*(\d{1,2})\s*[/-]\s*(\d{1,2})", lower)
        if m_slash:
            v1, v2 = int(m_slash.group(1)), int(m_slash.group(2))
            raw_str = f"{v1}/{v2}"
            if 1 <= v1 <= 31 and 1 <= v2 <= 12:
                # e.g. 24/10, 15/3 -> day=v1, month=v2
                return (v1, v2, raw_str)
            elif 1 <= v1 <= 12 and 1 <= v2 <= 31:
                # e.g. 10/24 (month/day or day/month) -> day=v2, month=v1
                return (v2, v1, raw_str)
        # Check if single day: "ngày 24", "mùng 5"
        m_single = re.search(r"(?:ngày|mùng)\s*(\d{1,2})\b", lower)
        if m_single:
            d = int(m_single.group(1))
            if 1 <= d <= 31:
                return (d, None, f"ngày {d}")
        return None

    def _parse_target_time(self, text: str) -> str:
        lower = text.lower()
        is_pm = any(w in lower for w in ["chiều", "tối", "pm"])
        m_time = re.search(r"(?:lúc\s+)?(\d{1,2})[:h](\d{2})?", lower)
        if m_time:
            hour = int(m_time.group(1))
            minute = int(m_time.group(2)) if m_time.group(2) else 0
            if is_pm and hour < 12:
                hour += 12
            if 0 <= hour <= 23 and 0 <= minute <= 59:
                return f"{hour:02d}:{minute:02d}"
        m_gio = re.search(r"(\d{1,2})\s*(?:giờ|h)", lower)
        if m_gio:
            hour = int(m_gio.group(1))
            if is_pm and hour < 12:
                hour += 12
            if 0 <= hour <= 23:
                return f"{hour:02d}:00"
        return "07:00"

    def _parse_occasion(self, text: str) -> str:
        lower = text.lower()
        m = re.search(r"\bgiỗ\s+([\w\s]{1,20}?)(?=\s+(?:vào|lúc|ngày|\d{1,2}|\.|\,|$|\n))", lower)
        if m:
            name = m.group(1).strip()
            if name:
                return f"Giỗ {name}"
            return "Giỗ cụ"
        if "giỗ" in lower:
            return "Giỗ cụ"
        if "lễ tạ" in lower:
            return "Lễ tạ"
        if "tất niên" in lower:
            return "Lễ tất niên"
        return "Ngày lễ gia đình"


    async def handle_in_scope_message(
        self,
        user_message: str,
        scope_result: IntentScopeResult,
        llm_service: Any,
        context: Optional[Dict[str, Any]] = None,
    ) -> Union[str, Tuple[str, Optional[Dict[str, Any]]]]:
        lower = user_message.lower()

        # Reminder Capability Handling (Core System Reminder Engine)
        has_remind_word = any(k in lower for k in ["nhắc", "hẹn giờ", "báo thức", "lên lịch nhắc", "cài đặt nhắc", "tự động thông báo"])
        has_spiritual_word = any(w in lower for w in ["thắp hương", "mùng 1", "rằm", "giỗ", "sóc", "vọng", "lễ", "ngày âm", "ngày khác", "tuỳ chọn", "tùy chọn"])
        has_date_slot = bool(re.search(r"\b\d{1,2}[/-]\d{1,2}\b", lower) or re.search(r"(?:ngày|mùng)\s*\d{1,2}", lower))

        if (
            scope_result.matched_capability_id == "reminder"
            or (has_remind_word and has_spiritual_word)
            or (has_date_slot and (has_spiritual_word or any(w in lower for w in ["lúc", "giờ", "giỗ", "cụ"])))
            or any(w in lower for w in ["ngày khác tuỳ chọn", "chọn ngày khác"])
        ):
            rem_svc = get_reminders_service()
            parsed_date = self._parse_lunar_date(user_message)
            has_custom_intent = any(w in lower for w in ["ngày khác", "tuỳ chọn", "tùy chọn", "giỗ", "đặt lịch riêng", "lễ riêng"])
            has_mung_1 = "mùng 1" in lower or "ngày 1" in lower or "sóc" in lower
            has_ram = "rằm" in lower or "ngày 15" in lower or "vọng" in lower
            is_confirm = any(w in lower for w in ["xác nhận", "đồng ý", "lưu lịch", "chốt", "tôi chọn lịch nhắc"])

            # 1. User provided a specific custom lunar date (e.g. 10/24, 15/3, 20 tháng 8)
            if parsed_date:
                day, month, raw_str = parsed_date
                occasion = self._parse_occasion(user_message)
                target_time = self._parse_target_time(user_message)
                sched_type = "lunar_yearly" if month else "lunar_monthly"
                created = rem_svc.create_reminder(
                    ReminderCreate(
                        agent_id="thay_cung",
                        title=f"Nhắc ngày {occasion}",
                        description=f"Nhắc Giám đốc thắp hương ngày {occasion} vào {raw_str} Âm lịch lúc {target_time}",
                        schedule=ReminderSchedule(type=sched_type, days=[day], month=month),
                        target_time=target_time,
                        occasion=occasion,
                        custom_payload={"type": "custom_lunar_anniversary"},
                        is_enabled=True,
                    )
                )
                return (
                    f"Dạ thưa Giám đốc! Thầy đã cài đặt lịch nhắc nhở ngày **{raw_str} Âm lịch** (dịp **{occasion}**) vào lúc **{target_time}** cho sếp rồi ạ!\n\n"
                    f"🏮 *Cơ chế hoạt động 24/24:* Đến đúng ngày giờ đó, Thầy sẽ chủ động gửi lời chúc và nhắc nhở vào khung chat cho sếp thắp nén nhang thành kính. "
                    f"Sếp có thể vào mục **Nhân viên** để xem lại hoặc bật/tắt lịch nhắc bất cứ lúc nào nhé!"
                )

            # 2. User chose "Ngày khác tuỳ chọn" without date -> Ask ONLY for the required date!
            if has_custom_intent:
                mung1_ram_saved_prefix = ""
                if (has_mung_1 and has_ram) or (is_confirm and (has_mung_1 or has_ram)):
                    if has_mung_1 and has_ram:
                        rem_svc.create_reminder(
                            ReminderCreate(
                                agent_id="thay_cung",
                                title="Nhắc thắp hương Mùng 1 & Ngày Rằm",
                                description="Nhắc Giám đốc thắp hương ngày Mùng 1 (sóc) và Ngày rằm 15 (vọng)",
                                schedule=ReminderSchedule(type="lunar_monthly", days=[1, 15]),
                                target_time="07:00",
                                occasion="Lễ sóc vọng hàng tháng",
                                custom_payload={"type": "lunar_bi_monthly"},
                                is_enabled=True,
                            )
                        )
                        mung1_ram_saved_prefix = (
                            "Dạ thưa Giám đốc! Thầy đã kích hoạt trước tác vụ nhắc nhở tự động cho ngày **Mùng 1 (sóc)** và **Ngày rằm 15 (vọng)** lúc 07:00 sáng hàng tháng cho sếp rồi ạ!\n\n"
                            "Còn về **Ngày khác tuỳ chọn**, "
                        )
                    elif has_mung_1:
                        rem_svc.create_reminder(
                            ReminderCreate(
                                agent_id="thay_cung",
                                title="Nhắc thắp hương Mùng 1",
                                description="Nhắc Giám đốc thắp hương ngày Mùng 1 hàng tháng",
                                schedule=ReminderSchedule(type="lunar_monthly", days=[1]),
                                target_time="07:00",
                                occasion="Lễ mùng 1 hàng tháng",
                                custom_payload={"type": "lunar_day_1"},
                                is_enabled=True,
                            )
                        )
                        mung1_ram_saved_prefix = (
                            "Dạ thưa Giám đốc! Thầy đã kích hoạt trước tác vụ nhắc nhở ngày **Mùng 1** lúc 07:00 sáng cho sếp rồi ạ!\n\n"
                            "Còn về **Ngày khác tuỳ chọn**, "
                        )
                    elif has_ram:
                        rem_svc.create_reminder(
                            ReminderCreate(
                                agent_id="thay_cung",
                                title="Nhắc thắp hương Ngày Rằm",
                                description="Nhắc Giám đốc thắp hương ngày Rằm 15 hàng tháng",
                                schedule=ReminderSchedule(type="lunar_monthly", days=[15]),
                                target_time="07:00",
                                occasion="Lễ ngày rằm hàng tháng",
                                custom_payload={"type": "lunar_day_15"},
                                is_enabled=True,
                            )
                        )
                        mung1_ram_saved_prefix = (
                            "Dạ thưa Giám đốc! Thầy đã kích hoạt trước tác vụ nhắc nhở **Ngày Rằm (15 âm)** lúc 07:00 sáng cho sếp rồi ạ!\n\n"
                            "Còn về **Ngày khác tuỳ chọn**, "
                        )

                if not mung1_ram_saved_prefix:
                    intro = "Dạ thưa Giám đốc! "
                else:
                    intro = mung1_ram_saved_prefix

                return (
                    f"{intro}Sếp muốn Thầy lên lịch nhắc vào ngày âm lịch nào ạ?\n\n"
                    f"👉 Sếp chỉ cần nhắn ngày (ví dụ: *'giỗ cụ 10/24 lúc 2:04'* hoặc *'15/3'*), Thầy sẽ tự động nhận diện ngày âm, dịp lễ và giờ để lưu lịch chạy ngầm 24/24 ngay cho sếp ạ!"
                )

            # 3. User confirming Mùng 1 & Rằm (without custom date)
            if (is_confirm or (has_mung_1 and has_ram)) and any(w in lower for w in ["xác nhận", "đồng ý", "lưu lịch", "chốt", "tôi chọn lịch nhắc", "nhé", "nhe", "nha", "giúp"]):
                rem_svc.create_reminder(
                    ReminderCreate(
                        agent_id="thay_cung",
                        title="Nhắc thắp hương Mùng 1 & Ngày Rằm",
                        description="Nhắc Giám đốc thắp hương ngày Mùng 1 (sóc) và Ngày rằm 15 (vọng)",
                        schedule=ReminderSchedule(type="lunar_monthly", days=[1, 15]),
                        target_time="07:00",
                        occasion="Lễ sóc vọng hàng tháng",
                        custom_payload={"type": "lunar_bi_monthly"},
                        is_enabled=True,
                    )
                )
                return (
                    "Dạ thưa Giám đốc! Thầy đã kích hoạt tác vụ ngầm tự động nhắc nhở sếp vào lúc **07:00 sáng ngày Mùng 1 (sóc)** và **Ngày rằm 15 (vọng)** hàng tháng rồi ạ!\n\n"
                    "🏮 *Cơ chế hoạt động 24/24:* Cứ đến sáng ngày sóc vọng, Thầy sẽ tự động gửi thông báo và lời chúc hanh thông vào khung chat này để sếp thắp hương thanh tịnh. "
                    "Sếp có thể vào mục **Nhân viên** để bật/tắt hoặc điều chỉnh bất kỳ lúc nào nhé!"
                )

            # Default: User asks to set up reminder -> Present interactive multi-checkbox
            reply_text = (
                "Dạ thưa Giám đốc! Thầy luôn sẵn lòng túc trực 24/24 để nhắc nhở sếp chuyện lễ nghi, sóc vọng cho tâm an việc hanh thông.\n\n"
                "Sếp muốn Thầy chủ động gửi thông báo nhắc nhở vào những ngày nào dưới đây ạ?"
            )
            interactive_config = {
                "config_type": "reminder_days",
                "title": "Chọn ngày nhắc nhở thắp hương tự động:",
                "is_multi_select": True,
                "options": [
                    {"id": "day_1", "label": "Mùng 1 âm lịch (ngày Sóc)", "default_checked": True},
                    {"id": "day_15", "label": "Ngày rằm 15 âm lịch (ngày Vọng)", "default_checked": True},
                    {"id": "custom", "label": "Ngày khác tuỳ chọn (giỗ cụ, ngày lễ...)", "default_checked": False},
                ],
                "confirm_label": "Xác nhận lịch nhắc",
            }
            return (reply_text, interactive_config)

        # If LLM service is available, generate dynamic response with prompt
        try:
            if hasattr(llm_service, "primary") and llm_service.primary:
                prompt = (
                    f"{self.system_prompt}\n\n"
                    f"Nhiệm vụ: Trả lời câu hỏi của Giám đốc về văn hoá truyền thống.\n"
                    f"Khả năng khớp: {scope_result.matched_capability_id or 'Chung'}\n"
                    f"Câu hỏi của Giám đốc: \"{user_message}\"\n\n"
                    f"Hãy trả lời chi tiết, thành kính, văn phong công sở lịch thiệp kèm biểu tượng phù hợp."
                )
                resp = await llm_service.primary._send_prompt(prompt)
                if resp and len(resp.strip()) > 20:
                    return resp.strip()
        except Exception:
            pass

        # Project on fire / deadline / server emergency prayer
        if any(k in lower for k in ["cháy", "dự án", "deadline", "tiến độ", "server", "bug", "sập"]):
            return (
                "Dạ thưa Giám đốc! Thầy thấu hiểu sâu sắc nỗi lòng lúc này: dự án đang cháy khét lẹt, deadline dí sát gót mà bug vẫn nhảy múa.\n\n"
                "Sếp chớ hoảng loạn! Hãy hít một hơi thật sâu, bảo anh em pha ấm trà thơm và thành tâm hướng về bài **Văn khấn Giải hạn Dự án & Độ trì Server**:\n\n"
                "📜 *\"Nam mô A Di Đà Phật! Con kính lạy chín phương Trời, mười phương Chư Phật, lạy Thần Code, Thần Mạng, Thần Cloud và Quan Đương niên phụ trách IT.\n\n"
                "Hôm nay ngày lành tháng tốt, tín chủ con là Giám đốc vnverse cùng toàn thể đội ngũ dự án, cúi đầu thành tâm khẩn cầu: Xin các ngài xua tan mọi con bug quái ác, dẹp sạch deadlock, dập tắt ngọn lửa trễ tiến độ. Phù hộ cho database mượt mà, server đứng vững 99.999% uptime, deploy phát một ăn ngay không rollback, đối tác nghiệm thu vui vẻ, doanh số rực rỡ!\"*\n\n"
                "🍎 **Mâm lễ cấp tốc văn phòng:**\n"
                "• Một đĩa hoa quả tươi ngũ sắc thanh lọc tâm trí\n"
                "• Bánh kẹo ngọt ngào tiếp thêm đường huyết\n"
                "• Một thùng nước ngọt ướp lạnh cho anh em lập trình viên hạ hoả\n\n"
                "🙏 *Lời dặn của Thầy Cúng:* Tâm linh vững vàng giải toả 50% áp lực, 50% còn lại sếp nhớ nhắc anh em check kỹ Pull Request trước khi merge nhé!"
            )

        # Rich deterministic cultural responses as robust fallback
        if scope_result.matched_capability_id == "traditional_offerings_and_prayers" or any(
            k in lower for k in ["văn khấn", "bài cúng", "mâm lễ", "thắp hương", "lễ vật"]
        ):
            return (
                "Dạ thưa Giám đốc, về lễ vật và bài văn khấn chuẩn văn hoá công sở:\n\n"
                "🍎 **Mâm lễ đơn giản thanh tịnh:**\n"
                "• Hương (nhang), hoa tươi (cúc vàng hoặc hoa huệ)\n"
                "• Đĩa trái cây tươi ngũ quả\n"
                "• Trầu cau, chén nước sạch hoặc trà thơm\n"
                "• Nến hoặc đèn dầu\n\n"
                "📜 **Ý nghĩa văn khấn Mùng 1 & Rằm:**\n"
                "\"Nam mô A Di Đà Phật! Con kính lạy chín phương Trời, mười phương Chư Phật. "
                "Tín chủ con ngụ tại... Nhân tiết ngày rằm/mùng một, thành tâm sửa biện hương hoa, kính mời các bậc tiền nhân, thần linh thổ địa giáng lâm chứng giám, phù hộ toàn thể công ty hanh thông, công việc thuận lợi, trong ấm ngoài êm.\"\n\n"
                "🙏 *Lưu ý của Thầy Cúng:* Lễ bạc tâm thành, quan trọng nhất là tấm lòng ngay thẳng và đoàn kết trong công việc sếp nhé!"
            )

        if scope_result.matched_capability_id == "lunar_day_reminder" or any(
            k in lower for k in ["mùng 1", "rằm", "âm lịch", "ngày âm"]
        ):
            return (
                "Dạ thưa Giám đốc! Theo phong tục văn hoá Việt Nam:\n\n"
                "🏮 **Ngày Mùng 1 (Sóc):** Ngày khởi đầu của tháng âm lịch, tượng trưng cho sự hanh thông, may mắn của công ty. Thường thắp hương sớm cầu bình an và may mắn.\n\n"
                "🌕 **Ngày Rằm (Vọng - ngày 15 âm):** Mặt trăng tròn vẹn, lòng người hướng thiện, cúng tạ ơn đất trời và tổ tiên đã phù hộ cho một nửa tháng vừa qua trọn vẹn.\n\n"
                "💡 *Mách nhỏ sếp:* Việc nhắc nhở tự động qua chuông thông báo đang được Bộ trưởng vnverse hoàn thiện. Hiện tại sếp có thể hỏi em bất cứ lúc nào để tra cứu ngày nhé!"
            )

        # Traditional holidays (Tết Đoan Ngọ, Hàn Thực, Vu Lan, Trung Thu, v.v.)
        if scope_result.matched_capability_id == "vietnamese_traditional_holidays" or any(
            k in lower
            for k in [
                "đoan ngọ",
                "hàn thực",
                "vu lan",
                "trung thu",
                "táo quân",
                "ông công",
                "ông táo",
                "hùng vương",
                "giỗ tổ",
                "tết",
                "ngày lễ",
                "lễ hội",
            ]
        ):
            if "đoan ngọ" in lower or "giết sâu bọ" in lower or "sâu bọ" in lower:
                return (
                    "Dạ thưa Giám đốc! **Tết Đoan Ngọ** (hay còn gọi là Tết Giết sâu bọ, Tết Đoan Dương) diễn ra vào ngày **Mùng 5 tháng 5 Âm lịch** hàng năm ạ!\n\n"
                    "🏮 **Ý nghĩa phong tục:**\n"
                    "Thời điểm này chuyển sang giữa hè, khí dương cực thịnh, sâu bọ và các mầm bệnh dễ phát sinh. Người Việt xưa làm lễ tạ ơn trời đất và ăn các món thanh lọc cơ thể để diệt trừ mầm bệnh nội thân và trừ sâu bọ bảo vệ mùa màng.\n\n"
                    "🍇 **Món ăn & Lễ vật truyền thống:**\n"
                    "• **Cơm rượu nếp** (rượu nếp cẩm hoặc nếp cái): Ăn vào sáng sớm khi thức dậy để 'say sưa' làm sâu bọ say và tiêu biến.\n"
                    "• **Bánh tro (bánh gio)** chấm mật mía ngọt mát, có tính giải nhiệt thanh nhiệt rất tốt.\n"
                    "• **Hoa quả đầu mùa có vị chua ngọt:** Mận hậu, vải thiều, đào, xoài...\n\n"
                    "💡 *Mách nhỏ chốn công sở:* Đến mùng 5/5 âm, sếp cứ bảo phòng Nhân sự mua một rổ mận hậu chín mọng và vài hũ cơm rượu nếp cho toàn thể anh em công ty nhâm nhi, vừa đúng phong tục diệt sâu bọ vừa gắn kết tinh thần team nhé Giám đốc!"
                )
            elif "hàn thực" in lower or "trôi nước" in lower:
                return (
                    "Dạ thưa Giám đốc! **Tết Hàn Thực** diễn ra vào ngày **Mùng 3 tháng 3 Âm lịch** hàng năm.\n\n"
                    "🏮 **Ý nghĩa & Phong tục:**\n"
                    "Người Việt cúng bánh trôi, bánh chay thành kính dâng lên tổ tiên với ý nghĩa hướng về cội nguồn, biểu trưng cho sự thanh bạch, tròn vẹn và hiếu nghĩa.\n\n"
                    "💡 *Mách nhỏ chốn công sở:* Dịp này công ty có thể tổ chức buổi trà chiều với bánh trôi bánh chay cho anh em cùng thưởng thức sếp nhé!"
                )
            elif "vu lan" in lower or "báo hiếu" in lower:
                return (
                    "Dạ thưa Giám đốc! **Đại lễ Vu Lan Báo Hiếu** diễn ra vào ngày **Rằm tháng 7 Âm lịch (15/7 Âm)**.\n\n"
                    "🏮 **Ý nghĩa & Phong tục:**\n"
                    "Là ngày lễ thiêng liêng để con cháu bày tỏ lòng hiếu thảo, tri ân công ơn sinh thành dưỡng dục của cha mẹ và tổ tiên; đồng thời kết hợp phong tục cúng xá tội vong nhân.\n\n"
                    "🙏 *Lời khuyên của Thầy Cúng:* Dịp này nên ăn chay thanh tịnh, làm việc thiện lành và dành thời gian gọi điện thăm hỏi cha mẹ sếp nhé!"
                )
            elif "trung thu" in lower or "trông trăng" in lower:
                return (
                    "Dạ thưa Giám đốc! **Tết Trung Thu** (Tết Đoàn Viên) diễn ra vào ngày **Rằm tháng 8 Âm lịch (15/8 Âm)**.\n\n"
                    "🏮 **Ý nghĩa & Phong tục:**\n"
                    "Thời điểm trăng tròn và sáng nhất trong năm, biểu tượng của sự sum vầy. Mâm cỗ gồm bánh nướng, bánh dẻo, bưởi, hồng và đèn ông sao rực rỡ.\n\n"
                    "💡 *Mách nhỏ công sở:* Sếp nhớ nhắc Công đoàn chuẩn bị hộp bánh Trung Thu tặng nhân sự và tổ chức phá cỗ cho các cháu nhỏ con em nhân viên nhé!"
                )
            elif "ông công" in lower or "ông táo" in lower or "táo quân" in lower:
                return (
                    "Dạ thưa Giám đốc! **Lễ cúng Ông Công Ông Táo** (Táo Quân chầu trời) diễn ra vào ngày **23 tháng Chạp (23/12 Âm lịch)**.\n\n"
                    "🏮 **Ý nghĩa & Phong tục:**\n"
                    "Tiễn Táo Quân cưỡi cá chép đỏ bay về trời để tâu bày với Ngọc Hoàng mọi việc lớn nhỏ trong năm qua. Mâm lễ gồm mũ áo Táo Quân, cá chép sống phóng sinh và mâm cỗ thanh tịnh."
                )
            elif "hùng vương" in lower or "giỗ tổ" in lower:
                return (
                    "Dạ thưa Giám đốc! **Ngày Giỗ Tổ Hùng Vương** diễn ra vào ngày **Mùng 10 tháng 3 Âm lịch** hàng năm.\n\n"
                    "📜 *\"Dù ai đi ngược về xuôi / Nhớ ngày Giỗ Tổ mùng mười tháng ba\"*\n\n"
                    "🏮 Đây là ngày Quốc lễ của toàn dân tộc Việt Nam nhằm tri ân công đức dựng nước của các Vua Hùng."
                )
            else:
                return (
                    "Dạ thưa Giám đốc! Về các ngày lễ tết truyền thống trong văn hoá Việt Nam:\n\n"
                    "🏮 **Các dịp lễ lớn trong năm âm lịch:**\n"
                    "• **Tết Nguyên Đán:** Mùng 1 tháng Giêng — Khởi đầu năm mới an khang thịnh vượng\n"
                    "• **Tết Hàn Thực:** Mùng 3 tháng 3 âm — Cúng bánh trôi bánh chay\n"
                    "• **Giỗ Tổ Hùng Vương:** Mùng 10 tháng 3 âm — Tưởng nhớ cội nguồn dân tộc\n"
                    "• **Tết Đoan Ngọ:** Mùng 5 tháng 5 âm — Tết diệt sâu bọ, ăn cơm rượu nếp, mận hậu\n"
                    "• **Đại lễ Vu Lan:** Rằm tháng 7 âm (15/7) — Mùa báo hiếu mẹ cha và tổ tiên\n"
                    "• **Tết Trung Thu:** Rằm tháng 8 âm (15/8) — Tết đoàn viên trông trăng\n"
                    "• **Tết Ông Công Ông Táo:** Ngày 23 tháng Chạp (23/12 âm) — Tiễn Táo Quân về trời\n\n"
                    "Sếp cần em tư vấn chi tiết về ý nghĩa, mâm lễ hoặc chuẩn bị cho dịp lễ nào cứ bảo em nhé!"
                )

        return (
            "Kính chào Giám đốc! Em là Thầy Cúng của công ty vnverse. "
            "Em chuyên lo chuyện lễ nghi, ngày rằm mùng một, văn khấn truyền thống để chốn công sở luôn an tâm, thanh tịnh. "
            "Hôm nay sếp cần tra cứu ngày âm, chuẩn bị mâm lễ hay xem ngày lễ nào ạ?"
        )
