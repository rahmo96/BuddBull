#!/usr/bin/env python3
"""Add missing Hebrew keys to gen_arb.py HE dict."""
from pathlib import Path

HE_ADDITIONS = {
    "adminNoUsersFound": "לא נמצאו משתמשים",
    "adminNoUsersMatchSearch": 'אין משתמשים התואמים ל-"{query}".',
    "adminUserCount": "{count, plural, =1{משתמש אחד} other{{count} משתמשים}}",
    "failedToLoadSports": "טעינת ספורט נכשלה: {error}",
    "adminNoSportsYet": "אין ספורט עדיין",
    "adminSportActive": "פעיל",
    "adminSportInactive": "לא פעיל",
    "adminEdit": "ערוך",
    "adminDeactivateSport": "השבת",
    "adminEditSport": "עריכת ספורט",
    "fieldNameLabel": "שם",
    "fieldIconLabel": "אייקון",
    "adminReporterLabel": "מדווח: @{username}",
    "adminReportedUserLabel": "משתמש מדווח: @{username}",
    "adminReportedGameLabel": "משחק מדווח: {title}",
    "fallbackUnknown": "לא ידוע",
    "statusLabel": "סטטוס",
    "adminNotesLabel": "הערות מנהל",
    "adminSearchUserPrompt": "הקלד כדי למצוא משתמש ולנהל את החשבון שלו.",
    "adminNoUsersInDatabase": "אין משתמשים במסד הנתונים עדיין.",
    "adminSearchMatchCount": "{count, plural, =1{התאמה אחת} other{{count} התאמות}}",
    "adminRecentUsersTotal": 'משתמשים אחרונים ({total} סה"כ)',
    "adminViewAllResultsInUsers": "הצג את כל {total} התוצאות במשתמשים",
    "adminOpenFullUsersList": "פתח רשימת משתמשים מלאה",
    "emptyNoConversations": "אין שיחות עדיין",
    "emptyConversationsHint": "התחל שיחה על ידי לחיצה על סמל העריכה למעלה או פתיחת משחק ולחיצה על צ'אט.",
    "chatTypingSingle": "{names} מקליד...",
    "chatTypingMultiple": "{names} מקלידים...",
    "replyingToName": "משיב ל-{name}",
    "chatMembersCount": "{count, plural, =1{חבר אחד} other{{count} חברים}}",
    "pinnedMessageLabel": "הודעה מוצמדת",
    "emptyNoMessagesYet": "אין הודעות עדיין",
    "relativeYesterday": "אתמול",
    "sectionNotifications": "התראות",
    "sectionAppearance": "מראה",
    "placeCouldNotResolve": "לא ניתן לאתר מקום זה. נסה אחר.",
}

EN_ADDITIONS = {
    "placeCouldNotResolve": "Could not resolve this place. Try another.",
}

path = Path(__file__).resolve().parent / "gen_arb.py"
text = path.read_text(encoding="utf-8")
marker = "\n}\n\nMETA ="
idx = text.find(marker)
if idx == -1:
    raise SystemExit("marker not found")

# Patch HE block only if keys missing
for k, v in HE_ADDITIONS.items():
    if f'"{k}":' not in text.split("HE = ")[1]:
        text = text[:idx] + f'    "{k}": "{v}",\n' + text[idx:]

path.write_text(text, encoding="utf-8")
print("patched", len(HE_ADDITIONS), "HE keys")
