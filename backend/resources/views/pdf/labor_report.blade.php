<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Labor Report</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 11px; color: #111; }
        h1, h2, h3 { margin: 0 0 6px 0; }
        .header { margin-bottom: 12px; }
        .section-title { font-weight: bold; margin-top: 16px; margin-bottom: 6px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 8px; }
        th, td { border: 1px solid #ddd; padding: 4px 6px; text-align: left; }
        th { background: #f3f3f3; }
        .calendar { margin-top: 8px; }
        .calendar th, .calendar td { text-align: center; font-size: 9px; padding: 3px; }
        .status-P { color: #2e7d32; font-weight: bold; }
        .status-A { color: #d32f2f; font-weight: bold; }
        .status-Off { color: #455a64; font-weight: bold; }
        .status-HD { color: #fb8c00; font-weight: bold; }
        .status-OT { color: #1a73e8; font-weight: bold; }
        .small { font-size: 9px; color: #666; }
    </style>
</head>
<body>
@php
    $month = $data['month'];
    $year = $data['year'];
    $staffName = $data['staff_name'] ?? '';
    $salaryType = $data['salary_type'] ?? '';
    $salaryAmount = $data['salary_amount'] ?? 0;
    $overtimeCharges = $data['overtime_charges'] ?? 0;
    $attendance = $data['attendance_details'] ?? [];
    $summary = $data['attendance_summary'] ?? [];
    $payment = $data['payment_summary'] ?? [];

    $daysInMonth = $summary['days_in_month'] ?? cal_days_in_month(CAL_GREGORIAN, $month, $year);
    $firstDay = \Carbon\Carbon::create($year, $month, 1);
    $startWeekday = (int) $firstDay->dayOfWeekIso; // 1=Mon ... 7=Sun

    $byDay = [];
    foreach ($attendance as $item) {
        $d = (int) \Carbon\Carbon::parse($item['date'])->day;
        $byDay[$d] = $item;
    }
@endphp

<div class="header">
    <h2>Labor Report</h2>
    <div>{{ $staffName }}</div>
    <div>{{ $month }}/{{ $year }}</div>
</div>

<div class="section">
    <div class="section-title">Staff details</div>
    <table>
        <tr><th>Name</th><td>{{ $staffName }}</td></tr>
        <tr><th>Phone</th><td>{{ $data['phone_number'] ?? '' }}</td></tr>
        <tr><th>Salary type</th><td>{{ $salaryType }}</td></tr>
        <tr><th>Salary rate</th><td>₹{{ number_format($salaryAmount, 2) }}</td></tr>
        <tr><th>Overtime rate</th><td>₹{{ number_format($overtimeCharges, 2) }} per hour</td></tr>
    </table>
</div>

<div class="section">
    <div class="section-title">Attendance calendar</div>
    <table class="calendar">
        <tr>
            <th>Mon</th><th>Tue</th><th>Wed</th><th>Thu</th><th>Fri</th><th>Sat</th><th>Sun</th>
        </tr>
        @php
            $day = 1;
            $cell = 1;
        @endphp
        @while ($day <= $daysInMonth)
            <tr>
                @for ($col = 1; $col <= 7; $col++, $cell++)
                    @php
                        $showDay = null;
                        if ($cell >= $startWeekday && $day <= $daysInMonth) {
                            $showDay = $day;
                            $day++;
                        }
                        $att = $showDay !== null && isset($byDay[$showDay]) ? $byDay[$showDay] : null;
                        $status = $att['status'] ?? '';
                        $multiplier = $att['pay_multiplier'] ?? 1;
                        $displayStatus = $status;
                        if ($status === 'P' && $multiplier > 1) {
                            // Format multiplier nicely (e.g., 2, 1.5)
                            $multiplierFormatted = rtrim(rtrim(number_format($multiplier, 2, '.', ''), '0'), '.');
                            $displayStatus = 'P x' . $multiplierFormatted;
                        }
                        $cls = $status ? 'status-' . $status : '';
                    @endphp
                    <td>
                        @if($showDay !== null)
                            <div>{{ $showDay }}</div>
                            @if($status)
                                <div class="{{ $cls }}">{{ $displayStatus }}</div>
                            @endif
                        @endif
                    </td>
                @endfor
            </tr>
        @endwhile
    </table>
    <div class="small">
        Legend: P = Present, A = Absent, OT = Overtime, Off = Week off, HD = Half day
    </div>
</div>

<div class="section">
    <div class="section-title">Payment summary</div>
    <table>
        <tr><th>Basic earnings</th><td>₹{{ number_format($payment['basic_earnings'] ?? 0, 2) }}</td></tr>
        <tr><th>Overtime earnings</th><td>₹{{ number_format($payment['overtime_earnings'] ?? 0, 2) }}</td></tr>
        <tr><th>Total earnings</th><td>₹{{ number_format($payment['total_earnings'] ?? 0, 2) }}</td></tr>
        <tr><th>Advance payments</th><td>-₹{{ number_format($payment['advance_payments'] ?? 0, 2) }}</td></tr>
        <tr><th>Net payment</th><td>₹{{ number_format($payment['net_payment'] ?? 0, 2) }}</td></tr>
        <tr><th>Previous due</th><td>₹{{ number_format($payment['previous_due_total'] ?? 0, 2) }}</td></tr>
        <tr><th>Total amount due</th><td>₹{{ number_format($payment['total_amount_due'] ?? 0, 2) }}</td></tr>
        <tr><th>Remaining total due</th><td>₹{{ number_format($payment['remaining_total_due'] ?? 0, 2) }}</td></tr>
    </table>
</div>

<div class="section">
    <div class="section-title">Attendance details</div>
    <table>
        <thead>
        <tr>
            <th>Date</th>
            <th>Status</th>
            <th>In</th>
            <th>Out</th>
            <th>Overtime (h)</th>
            <th>Advance</th>
        </tr>
        </thead>
        <tbody>
        @foreach($attendance as $row)
            <tr>
                <td>{{ $row['date'] }}</td>
                <td>{{ $row['status'] }}</td>
                <td>{{ $row['in_time'] ?? '-' }}</td>
                <td>{{ $row['out_time'] ?? '-' }}</td>
                <td>{{ number_format($row['overtime_hours'] ?? 0, 2) }}</td>
                <td>₹{{ number_format($row['advance_amount'] ?? 0, 2) }}</td>
            </tr>
        @endforeach
        </tbody>
    </table>
</div>

</body>
</html>

