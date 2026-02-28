<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\CashbookExpense;
use App\Models\Staff;
use App\Models\StaffPeriodPayment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    /**
     * Get labor report for a staff member
     *
     * @param Request $request
     * @param int $staffId
     * @return \Illuminate\Http\JsonResponse
     */
    public function getLaborReport(Request $request, $staffId)
    {
        $validated = $request->validate([
            'month' => 'nullable|integer|min:1|max:12',
            'year' => 'nullable|integer|min:2000|max:2100',
        ]);

        // Verify staff belongs to authenticated user
        $staff = Staff::where('id', $staffId)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $month = $validated['month'] ?? now()->month;
        $year = $validated['year'] ?? now()->year;

        // Get all attendance records for the month
        $attendances = Attendance::where('staff_id', $staffId)
            ->whereYear('date', $year)
            ->whereMonth('date', $month)
            ->orderBy('date', 'asc')
            ->get();

        // Calculate attendance summary
        // Present count includes ALL present days (with or without overtime)
        $presentCount = $attendances->where('status', 'present')->count();
        $absentCount = $attendances->where('status', 'absent')->count();
        $overtimeCount = $attendances->where('status', 'present')
            ->where('overtime_hours', '>', 0)
            ->count();
        $weekOffCount = $attendances->where('status', 'off')->count();
        $halfDayCount = $attendances->where('status', 'half_day')->count();

        // Working days = days in month minus off days (off days are not counted for monthly/weekly pay)
        $daysInMonth = (int) cal_days_in_month(CAL_GREGORIAN, $month, $year);
        $workingDaysInMonth = $daysInMonth - $weekOffCount;

        // Calculate payment summary based on salary type
        // Basic earnings includes ALL present days (OT days are also present days)
        // Now also applies pay_multiplier per day; monthly/weekly use working days (exclude off)
        $basicEarnings = $this->calculateBasicEarnings(
            $staff->salary_type,
            $staff->salary_amount,
            $presentCount,
            $halfDayCount,
            $month,
            $year,
            $attendances, // Pass attendances for hourly calculation and pay_multiplier
            $weekOffCount
        );

        $overtimeEarnings = $this->calculateOvertimeEarnings(
            $staff->overtime_charges,
            $attendances
        );

        $totalEarnings = $basicEarnings + $overtimeEarnings;
        $advancePayments = $attendances->sum('advance_amount');
        $netPayment = $totalEarnings - $advancePayments;

        // Amount paid this period (custom payments) and previous due
        $periodPaymentRow = StaffPeriodPayment::where('staff_id', $staffId)
            ->where('year', $year)
            ->where('month', $month)
            ->first();
        $amountPaidThisPeriod = $periodPaymentRow ? (float) $periodPaymentRow->amount_paid : 0.0;
        $amountPaidAt = $periodPaymentRow && $periodPaymentRow->updated_at ? $periodPaymentRow->updated_at->toIso8601String() : null;
        $remainingDueThisPeriod = max(0, $netPayment - $amountPaidThisPeriod);

        $previousData = $this->getPreviousDueBreakdown($staff, $month, $year);
        $previousDueBreakdown = $previousData['breakdown'];
        $previousBalanceTotal = (float) ($previousData['balance_total'] ?? 0);
        $previousDueTotal = $previousBalanceTotal > 0 ? $previousBalanceTotal : 0.0;
        $totalAmountDue = max(0, $previousBalanceTotal + $netPayment);
        $remainingTotalDue = max(0, $previousBalanceTotal + $remainingDueThisPeriod);

        // Calculate total worked hours and overtime hours
        $totalWorkedHours = $this->calculateTotalWorkedHours($attendances, $staff->salary_type);
        $totalOvertimeHours = $attendances->sum('overtime_hours');

        // Format attendance details
        $attendanceDetails = $attendances->map(function ($attendance) use ($staff, $month, $year, $weekOffCount) {
            $status = $attendance->status;
            if ($status === 'present' && $attendance->overtime_hours > 0) {
                $status = 'OT';
            } elseif ($status === 'off') {
                $status = 'Off';
            } elseif ($status === 'present') {
                $status = 'P';
            } elseif ($status === 'half_day') {
                $status = 'HD';
            } elseif ($status === 'absent') {
                $status = 'A';
            }

            // Calculate daily earnings based on status and salary type
            $dailyEarnings = $this->calculateDailyEarnings(
                $staff->salary_type,
                $staff->salary_amount,
                $staff->overtime_charges,
                $attendance->status,
                $attendance->overtime_hours,
                $attendance->worked_hours,
                $attendance->in_time,
                $attendance->out_time,
                $attendance->pay_multiplier ?? 1.0,
                $month,
                $year,
                $weekOffCount
            );

            return [
                'id' => $attendance->id,
                'date' => $attendance->date->format('Y-m-d'),
                'status' => $status,
                'in_time' => $attendance->in_time ? date('H:i', strtotime($attendance->in_time)) : null,
                'out_time' => $attendance->out_time ? date('H:i', strtotime($attendance->out_time)) : null,
                'overtime_hours' => (float) $attendance->overtime_hours,
                'worked_hours' => (float) $attendance->worked_hours,
                'pay_multiplier' => (float) ($attendance->pay_multiplier ?? 1.0),
                'advance_amount' => (float) $attendance->advance_amount,
                'daily_earnings' => round($dailyEarnings, 2),
            ];
        })->values();

        return response()->json([
            'success' => true,
            'message' => 'Labor report retrieved successfully',
            'data' => [
                'staff_id' => $staff->id,
                'staff_name' => $staff->name,
                'phone_number' => $staff->phone_number,
                'salary_type' => $staff->salary_type,
                'salary_amount' => (float) $staff->salary_amount,
                'overtime_charges' => (float) $staff->overtime_charges,
                'month' => $month,
                'year' => $year,
                'attendance_summary' => [
                    'present' => $presentCount,
                    'absent' => $absentCount,
                    'overtime' => $overtimeCount,
                    'week_off' => $weekOffCount,
                    'half_day' => $halfDayCount,
                    'days_in_month' => $daysInMonth,
                    'working_days' => $workingDaysInMonth,
                ],
                'payment_summary' => [
                    'basic_earnings' => round($basicEarnings, 2),
                    'overtime_earnings' => round($overtimeEarnings, 2),
                    'total_earnings' => round($totalEarnings, 2),
                    'advance_payments' => round($advancePayments, 2),
                    'net_payment' => round($netPayment, 2),
                    'amount_paid_this_period' => round($amountPaidThisPeriod, 2),
                    'amount_paid_at' => $amountPaidAt,
                    'remaining_due_this_period' => round($remainingDueThisPeriod, 2),
                    'previous_due_total' => round($previousDueTotal, 2),
                    'previous_due_breakdown' => $previousDueBreakdown,
                    'total_amount_due' => round($totalAmountDue, 2),
                    'remaining_total_due' => round($remainingTotalDue, 2),
                    'total_worked_hours' => round($totalWorkedHours, 2),
                    'total_overtime_hours' => round($totalOvertimeHours, 2),
                ],
                'attendance_details' => $attendanceDetails,
            ],
        ], 200);
    }

    /**
     * Calculate total worked hours from attendance records
     */
    private function calculateTotalWorkedHours($attendances, string $salaryType): float
    {
        $totalHours = 0;
        foreach ($attendances as $attendance) {
            if ($attendance->status === 'present' || $attendance->status === 'half_day') {
                // Use manual worked_hours if provided
                if ($attendance->worked_hours > 0) {
                    $totalHours += $attendance->worked_hours;
                } elseif ($attendance->in_time && $attendance->out_time) {
                    // Calculate from in/out times
                    $inTimestamp = strtotime($attendance->in_time);
                    $outTimestamp = strtotime($attendance->out_time);
                    if ($outTimestamp < $inTimestamp) {
                        $outTimestamp += 86400;
                    }
                    $hoursWorked = ($outTimestamp - $inTimestamp) / 3600;
                    // Subtract overtime hours from regular hours
                    $regularHours = max(0, $hoursWorked - ($attendance->overtime_hours ?? 0));
                    $totalHours += $regularHours;
                } else {
                    // Default hours if no data available
                    $totalHours += ($attendance->status === 'present' ? 8 : 4);
                }
            }
        }
        return $totalHours;
    }

    /**
     * Calculate basic earnings based on salary type
     * Now applies pay_multiplier per day for custom pay rates
     */
    private function calculateBasicEarnings(
        string $salaryType,
        float $salaryAmount,
        int $presentCount,
        int $halfDayCount,
        int $month,
        int $year,
        $attendances = null,
        int $offCount = 0
    ): float {
        $daysInMonth = (int) cal_days_in_month(CAL_GREGORIAN, $month, $year);
        $workingDaysInMonth = $daysInMonth - $offCount;

        // If we have attendance records, calculate per-day with pay_multiplier
        if ($attendances) {
            $totalEarnings = 0.0;

            foreach ($attendances as $attendance) {
                $multiplier = $attendance->pay_multiplier ?? 1.0;
                $dayEarnings = 0.0;
                
                if ($attendance->status === 'present') {
                    switch ($salaryType) {
                        case 'hourly':
                            if ($attendance->worked_hours > 0) {
                                $dayEarnings = $attendance->worked_hours * $salaryAmount;
                            } elseif ($attendance->in_time && $attendance->out_time) {
                                $inTimestamp = strtotime($attendance->in_time);
                                $outTimestamp = strtotime($attendance->out_time);
                                if ($outTimestamp < $inTimestamp) {
                                    $outTimestamp += 86400;
                                }
                                $hoursWorked = ($outTimestamp - $inTimestamp) / 3600;
                                $regularHours = max(0, $hoursWorked - ($attendance->overtime_hours ?? 0));
                                $dayEarnings = $regularHours * $salaryAmount;
                            } else {
                                $dayEarnings = 8 * $salaryAmount;
                            }
                            break;
                        case 'daily':
                            $dayEarnings = $salaryAmount;
                            break;
                        case 'weekly':
                            $dayEarnings = $salaryAmount / 7;
                            break;
                        case 'monthly':
                            $dayEarnings = $workingDaysInMonth > 0 ? $salaryAmount / $workingDaysInMonth : 0;
                            break;
                    }
                } elseif ($attendance->status === 'half_day') {
                    switch ($salaryType) {
                        case 'hourly':
                            if ($attendance->worked_hours > 0) {
                                $dayEarnings = $attendance->worked_hours * $salaryAmount;
                            } elseif ($attendance->in_time && $attendance->out_time) {
                                $inTimestamp = strtotime($attendance->in_time);
                                $outTimestamp = strtotime($attendance->out_time);
                                if ($outTimestamp < $inTimestamp) {
                                    $outTimestamp += 86400;
                                }
                                $hoursWorked = ($outTimestamp - $inTimestamp) / 3600;
                                $dayEarnings = $hoursWorked * $salaryAmount;
                            } else {
                                $dayEarnings = 4 * $salaryAmount;
                            }
                            break;
                        case 'daily':
                            $dayEarnings = $salaryAmount * 0.5;
                            break;
                        case 'weekly':
                            $dayEarnings = ($salaryAmount / 7) * 0.5;
                            break;
                        case 'monthly':
                            $dayEarnings = $workingDaysInMonth > 0 ? ($salaryAmount / $workingDaysInMonth) * 0.5 : 0;
                            break;
                    }
                }
                
                // Apply pay multiplier
                $totalEarnings += $dayEarnings * $multiplier;
            }
            
            return $totalEarnings;
        }
        
        // Fallback without attendance records (no multiplier applied)
        switch ($salaryType) {
            case 'hourly':
                $totalHours = ($presentCount * 8) + ($halfDayCount * 4);
                return $totalHours * $salaryAmount;

            case 'daily':
                return ($presentCount * $salaryAmount) + ($halfDayCount * $salaryAmount * 0.5);

            case 'weekly':
                $weeksWorked = ($presentCount + ($halfDayCount * 0.5)) / 7;
                return $weeksWorked * $salaryAmount;

            case 'monthly':
                $workingDays = $presentCount + ($halfDayCount * 0.5);
                return $workingDaysInMonth > 0 ? ($workingDays / $workingDaysInMonth) * $salaryAmount : 0;

            default:
                return 0.0;
        }
    }

    /**
     * Calculate overtime earnings
     */
    private function calculateOvertimeEarnings(float $overtimeRate, $attendances): float
    {
        $totalOvertimeHours = $attendances->sum('overtime_hours');
        return $totalOvertimeHours * $overtimeRate;
    }

    /**
     * Calculate daily earnings for a single attendance record
     * Applies pay_multiplier to basic earnings (not overtime)
     */
    private function calculateDailyEarnings(
        string $salaryType,
        float $salaryAmount,
        float $overtimeRate,
        string $status,
        float $overtimeHours,
        float $workedHours,
        $inTime,
        $outTime,
        float $payMultiplier,
        int $month,
        int $year,
        int $offCount = 0
    ): float {
        $basicEarnings = 0.0;
        $daysInMonth = (int) cal_days_in_month(CAL_GREGORIAN, $month, $year);
        $workingDaysInMonth = $daysInMonth - $offCount;

        // Calculate basic earnings for the day based on status
        switch ($status) {
            case 'present':
                // Full day earnings
                switch ($salaryType) {
                    case 'hourly':
                        // Use manual worked_hours if provided
                        if ($workedHours > 0) {
                            $basicEarnings = $workedHours * $salaryAmount;
                        } elseif ($inTime && $outTime) {
                            $inTimestamp = strtotime($inTime);
                            $outTimestamp = strtotime($outTime);
                            if ($outTimestamp < $inTimestamp) {
                                $outTimestamp += 86400;
                            }
                            $hoursWorked = ($outTimestamp - $inTimestamp) / 3600;
                            $regularHours = max(0, $hoursWorked - $overtimeHours);
                            $basicEarnings = $regularHours * $salaryAmount;
                        } else {
                            // Default to 8 hours if no data available
                            $basicEarnings = 8 * $salaryAmount;
                        }
                        break;
                    case 'daily':
                        $basicEarnings = $salaryAmount;
                        break;
                    case 'weekly':
                        $basicEarnings = $salaryAmount / 7;
                        break;
                    case 'monthly':
                        $basicEarnings = $workingDaysInMonth > 0 ? $salaryAmount / $workingDaysInMonth : 0;
                        break;
                }
                break;

            case 'half_day':
                // Half day earnings
                switch ($salaryType) {
                    case 'hourly':
                        // Use manual worked_hours if provided
                        if ($workedHours > 0) {
                            $basicEarnings = $workedHours * $salaryAmount;
                        } elseif ($inTime && $outTime) {
                            $inTimestamp = strtotime($inTime);
                            $outTimestamp = strtotime($outTime);
                            if ($outTimestamp < $inTimestamp) {
                                $outTimestamp += 86400;
                            }
                            $hoursWorked = ($outTimestamp - $inTimestamp) / 3600;
                            $basicEarnings = $hoursWorked * $salaryAmount;
                        } else {
                            // Default to 4 hours for half day
                            $basicEarnings = 4 * $salaryAmount;
                        }
                        break;
                    case 'daily':
                        $basicEarnings = $salaryAmount * 0.5;
                        break;
                    case 'weekly':
                        $basicEarnings = ($salaryAmount / 7) * 0.5;
                        break;
                    case 'monthly':
                        $basicEarnings = $workingDaysInMonth > 0 ? ($salaryAmount / $workingDaysInMonth) * 0.5 : 0;
                        break;
                }
                break;

            case 'absent':
            case 'off':
                // No earnings for absent or off days
                $basicEarnings = 0.0;
                break;
        }

        // Apply pay multiplier to basic earnings
        $dailyEarnings = $basicEarnings * $payMultiplier;

        // Add overtime earnings if present (overtime is NOT multiplied)
        if ($status === 'present' && $overtimeHours > 0) {
            $dailyEarnings += $overtimeHours * $overtimeRate;
        }

        return $dailyEarnings;
    }

    /**
     * Compute net payment (total_earnings - advance) for a staff period from attendance.
     */
    private function computePeriodNetPayment(Staff $staff, int $month, int $year): float
    {
        $attendances = Attendance::where('staff_id', $staff->id)
            ->whereYear('date', $year)
            ->whereMonth('date', $month)
            ->get();
        if ($attendances->isEmpty()) {
            return 0.0;
        }
        $weekOffCount = $attendances->where('status', 'off')->count();
        $presentCount = $attendances->where('status', 'present')->count();
        $halfDayCount = $attendances->where('status', 'half_day')->count();
        $basicEarnings = $this->calculateBasicEarnings(
            $staff->salary_type,
            (float) $staff->salary_amount,
            $presentCount,
            $halfDayCount,
            $month,
            $year,
            $attendances,
            $weekOffCount
        );
        $overtimeEarnings = $this->calculateOvertimeEarnings(
            (float) $staff->overtime_charges,
            $attendances
        );
        $advancePayments = $attendances->sum('advance_amount');
        return $basicEarnings + $overtimeEarnings - $advancePayments;
    }

    /**
     * Get previous due breakdown and total balance before the current period.
     *
     * balance_total is the sum of (net - amount_paid) for all past months.
     * It can be positive (overall due) or negative (overall credit).
     * The breakdown only includes months where the balance is positive (actual due).
     */
    private function getPreviousDueBreakdown(Staff $staff, int $reportMonth, int $reportYear): array
    {
        $pastPeriods = Attendance::where('staff_id', $staff->id)
            ->whereRaw('(YEAR(date) < ?) OR (YEAR(date) = ? AND MONTH(date) < ?)', [$reportYear, $reportYear, $reportMonth])
            ->selectRaw('YEAR(date) as year, MONTH(date) as month')
            ->groupByRaw('YEAR(date), MONTH(date)')
            ->orderByRaw('YEAR(date) DESC, MONTH(date) DESC')
            ->limit(24)
            ->get();

        $paymentMap = StaffPeriodPayment::where('staff_id', $staff->id)
            ->get()
            ->keyBy(fn ($r) => $r->year . '-' . $r->month);

        $monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        $breakdown = [];
        $balanceTotal = 0.0;

        foreach ($pastPeriods as $p) {
            $net = $this->computePeriodNetPayment($staff, (int) $p->month, (int) $p->year);
            $rec = $paymentMap->get($p->year . '-' . $p->month);
            $amountPaid = $rec ? (float) $rec->amount_paid : 0.0;
            $balance = round($net - $amountPaid, 2);
            $balanceTotal += $balance;

            if ($balance <= 0) {
                // Credit or fully-paid month: affects balance_total but not positive due breakdown.
                continue;
            }

            $breakdown[] = [
                'year' => (int) $p->year,
                'month' => (int) $p->month,
                'month_label' => $monthNames[(int) $p->month - 1] . ' ' . $p->year,
                'net' => round($net, 2),
                'amount_paid' => round($amountPaid, 2),
                'due' => $balance,
            ];
        }

        return [
            'breakdown' => $breakdown,
            'balance_total' => $balanceTotal,
        ];
    }

    /**
     * Record a custom payment for a staff period (upserts amount_paid for that month).
     * Also creates a cashbook expense so the payment appears in expenses with payment method.
     */
    public function recordPayment(Request $request, $staffId)
    {
        $validated = $request->validate([
            'month' => 'required|integer|min:1|max:12',
            'year' => 'required|integer|min:2000|max:2100',
            'amount' => 'required|numeric|min:0',
            'payment_method' => 'nullable|string|in:upi,bank_transfer,cash,other',
        ]);

        $staff = Staff::where('id', $staffId)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $paymentMethod = $validated['payment_method'] ?? 'other';
        $monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        $monthLabel = $monthNames[$validated['month'] - 1] . ' ' . $validated['year'];

        StaffPeriodPayment::updateOrCreate(
            [
                'staff_id' => $staff->id,
                'year' => $validated['year'],
                'month' => $validated['month'],
            ],
            [
                'amount_paid' => $validated['amount'],
                'payment_method' => $paymentMethod,
            ]
        );

        CashbookExpense::create([
            'user_id' => $request->user()->id,
            'date' => now()->toDateString(),
            'amount' => $validated['amount'],
            'description' => 'Staff payment: ' . $staff->name . ' - ' . $monthLabel,
            'payment_method' => $paymentMethod,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Payment recorded successfully',
        ], 200);
    }
}
