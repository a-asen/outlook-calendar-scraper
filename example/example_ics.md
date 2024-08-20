This example illustrates an example that worked on my import to

Note that only day events and all-day-events are coded slightly differently. 

#### Day event

```{ics}
BEGIN:VEVENT
SUMMARY:My important event
DTSTAMP:20240815T180000
DESCRIPTION:Longer Description
DTSTART;TZID=Europe/Berlin:20240815T180000
DTEND;TZID=Europe/Berlin:20240815T210000
LOCATION:San Francisco CA
END:VEVENT
```

#### All day event

```{ics}
BEGIN:VEVENT
### Below is Etesync stuff? ###
CREATED:20240809T075640Z
LAST-MODIFIED:20240809T075647Z
DTSTAMP:20240809T075647Z
UID:2d55f7c2-a7c4-4ae7-96fd-3a7115e32653
### Below is normal stuff ###
SUMMARY:Ross fast
DTSTART;VALUE=DATE:20240731
DTEND;VALUE=DATE:20240808
TRANSP:TRANSPARENT
END:VEVENT
```

---

#### Meta data

```{ics}
BEGIN:VCALENDAR
PRODID:-//Mozilla.org/NONSGML Mozilla Calendar V1.1//EN
VERSION:2.0
BEGIN:VTIMEZONE
TZID:Europe/Oslo
X-TZINFO:Europe/Oslo[2024a]
END:VTIMEZONE
# DATA HERE
# ...
END:VCALENDAR
```

#### iCalendar base

```{ics}
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
BEGIN:VEVENT
UID:uid1@example.com
ORGANIZER;CN=John Doe:MAILTO:john.doe@example.com
DTSTART:19970714T170000Z
DTEND:19970715T040000Z
SUMMARY:Bastille Day Party
GEO:48.85299;2.36885
END:VEVENT
END:VCALENDAR
```

[Source](https://en.wikipedia.org/wiki/ICalendar)
