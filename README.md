# בקר שימוש במחשב

פתרון PowerShell עבור Windows 11. בכל כניסה ל-Windows נפתחת הודעת אזהרה, לאחריה טופס עם שם משתמש, מטרת שימוש וזמן בדקות עד 120. בסיום הזמן המחשב נכבה אוטומטית, עם תזכורת 5 דקות לפני.

אחרי 21:00 מופיעה הודעה שאין להשתמש במחשב אחרי שעה 9 אלא במקרים דחופים, והזמן מוגבל אוטומטית ל-10 דקות.

## התקנה במחשב היעד

1. העתיקו את כל התיקייה למחשב היעד.
2. לחצו קליק ימני על `InstallAsAdmin.cmd` ובחרו Run as administrator.

אפשרות ידנית:

פתחו PowerShell כ-Administrator בתוך התיקייה והריצו:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
```

ההתקנה מעתיקה את הקבצים אל:

```text
C:\ProgramData\ComputerUsageController
```

ומגדירה Scheduled Task בשם:

```text
Computer Usage Controller
```

המשימה רצה בכל כניסה ל-Windows עבור משתמשים רגילים, כדי שהחלונות יופיעו למשתמש המחובר.

## ממשק ניהול

אחרי ההתקנה יופיע על שולחן העבודה קיצור דרך בשם:

```text
ניהול שימוש במחשב
```

הממשק מציג לכל שם משתמש כמה שעות ודקות השתמש בשבוע האחרון, וגם פירוט שימושים.

## בדיקה ללא התקנה

להרצת הטופס מיד מהמיקום הנוכחי:

```text
RunControllerNow.cmd
```

לפתיחת ממשק הניהול מהמיקום הנוכחי:

```text
OpenDashboard.cmd
```

## הסרה

פתחו PowerShell כ-Administrator והריצו:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\ComputerUsageController\Uninstall.ps1"
```

ההסרה מוחקת את המשימה המתוזמנת ואת קיצור הדרך. נתוני השימוש נשארים ב-`C:\ProgramData\ComputerUsageController\sessions` כדי שלא יימחקו בטעות.

## הערות

- זה אינו Windows Service אמיתי, משום ששירותים ב-Windows אינם מיועדים לפתוח חלונות וטפסים למשתמש המחובר. הפתרון משתמש ב-Scheduled Task בעת כניסה למערכת, שהוא המנגנון המתאים לחלונות אינטראקטיביים.
- אם המחשב נכבה לפני סיום הזמן שהוגדר, התהליך נפסק והזמן לא ממשיך לשימוש הבא.
- חישוב הזמן בפועל נעשה לפי פעימת חיים שנשמרת בערך פעם בדקה.
