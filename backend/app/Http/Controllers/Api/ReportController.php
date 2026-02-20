<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Staff;
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

        // Calculate payment summary based on salary type
        // Basic earnings includes ALL present days (OT days are also present days)
        $basicEarnings = $this->calculateBasicEarnings(
            $staff->salary_type,
            $staff->salary_amount,
            $presentCount,
            $halfDayCount,
            $month,
            $year,
            $attendances // Pass attendances for hourly calculation
        );

        $overtimeEarnings = $this->calculateOvertimeEarnings(
            $staff->overtime_charges,
            $attendances
        );

        $totalEarnings = $basicEarnings + $overtimeEarnings;
        $advancePayments = $attendances->sum('advance_amount');
        $netPayment = $totalEarnings - $advancePayments;

        // Format attendance details
        $attendanceDetails = $attendances->map(function ($attendance) use ($staff, $month, $year) {
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
                $attendance->in_time,
                $attendance->out_time,
                $month,
                $year
            );

            return [
                'id' => $attendance->id,
                'date' => $attendance->date->format('Y-m-d'),
                'status' => $status,
                'in_time' => $attendance->in_time ? date('H:i', strtotime($attendance->in_time)) : null,
                'out_time' => $attendance->out_time ? date('H:i', strtotime($attendance->out_time)) : null,
                'overtime_hours' => (float) $attendance->overtime_hours,
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
                ],
                'payment_summary' => [
                    'basic_earnings' => round($basicEarnings, 2),
                    'overtime_earnings' => round($overtimeEarnings, 2),
                    'total_earnings' => round($totalEarnings, 2),
                    'advance_payments' => round($advancePayments, 2),
                    'net_payment' => round($netPayment, 2),
                ],
                'attendance_details' => $attendanceDetails,
            ],
        ], 200);
    }

    /**
     * Calculate basic earnings based on salary type
     */
    private function calculateBasicEarnings(
        string $salaryType,
        float $salaryAmount,
        int $presentCount,
        int $halfDayCount,
        int $month,
        int $year,
        $attendances = null
    ): float {
        switch ($salaryType) {
            case 'hourly':
                // For hourly, calculate based on actual hours worked from attendance records
                if ($attendances) {
                    $totalRegularHours = 0;
                    foreach ($attendances as $attendance) {
                        if ($attendance->status === 'present' || $attendance->status === 'half_day') {
                            if ($attendance->in_time && $attendance->out_time) {
                                $inTimestamp = strtotime($attendance->in_time);
                                $outTimestamp = strtotime($attendance->out_time);
                                if ($outTimestamp < $inTimestamp) {
                                    $outTimestamp += 86400; // Add 24 hours
                                }
                                $hoursWorked = ($outTimestamp - $inTimestamp) / 3600;
                                // Subtract overtime hours from regular hours
                                $regularHours = max(0, $hoursWorked - ($attendance->overtime_hours ?? 0));
                                $totalRegularHours += $regularHours;
                            } else {
                                // Default to 8 hours for present, 4 for half day if times not available
                                $totalRegularHours += ($attendance->status === 'present' ? 8 : 4);
                            }
                        }
                    }
                    return $totalRegularHours * $salaryAmount;
                } else {
                    // Fallback: Assuming 8 hours per day for present, 4 hours for half day
                    $totalHours = ($presentCount * 8) + ($halfDayCount * 4);
                    return $totalHours * $salaryAmount;
                }

            case 'daily':
                // Present days count + half day counts as 0.5
                return ($presentCount * $salaryAmount) + ($halfDayCount * $salaryAmount * 0.5);

            case 'weekly':
                // Calculate weeks worked
                $weeksWorked = ($presentCount + ($halfDayCount * 0.5)) / 7;
                return $weeksWorked * $salaryAmount;

            case 'monthly':
                // Monthly salary is fixed, but prorated based on present days
                $daysInMonth = cal_days_in_month(CAL_GREGORIAN, $month, $year);
                $workingDays = $presentCount + ($halfDayCount * 0.5);
                return ($workingDays / $daysInMonth) * $salaryAmount;

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
     */
    private function calculateDailyEarnings(
        string $salaryType,
        float $salaryAmount,
        float $overtimeRate,
        string $status,
        float $overtimeHours,
        $inTime,
        $outTime,
        int $month,
        int $year
    ): float {
        $dailyEarnings = 0.0;

        // Calculate basic earnings for the day based on status
        switch ($status) {
            case 'present':
                // Full day earnings
                switch ($salaryType) {
                    case 'hourly':
                        // For hourly, calculate based on actual hours worked if available
                        if ($inTime && $outTime) {
                            $inTimestamp = strtotime($inTime);
                            $outTimestamp = strtotime($outTime);
                            // Handle case where out time is next day
                            if ($outTimestamp < $inTimestamp) {
                                $outTimestamp += 86400; // Add 24 hours
                            }
                            $hoursWorked = ($outTimestamp - $inTimestamp) / 3600;
                            // Subtract overtime hours from regular hours
                            $regularHours = max(0, $hoursWorked - $overtimeHours);
                            $dailyEarnings = $regularHours * $salaryAmount;
                        } else {
                            // Default to 8 hours if times not available
                            $dailyEarnings = 8 * $salaryAmount;
                        }
                        break;
                    case 'daily':
                        $dailyEarnings = $salaryAmount;
                        break;
                    case 'weekly':
                        $dailyEarnings = $salaryAmount / 7; // Weekly rate divided by 7 days
                        break;
                    case 'monthly':
                        $daysInMonth = cal_days_in_month(CAL_GREGORIAN, $month, $year);
                        $dailyEarnings = $salaryAmount / $daysInMonth;
                        break;
                }
                break;

            case 'half_day':
                // Half day earnings
                switch ($salaryType) {
                    case 'hourly':
                        // For hourly half day, calculate based on actual hours if available
                        if ($inTime && $outTime) {
                            $inTimestamp = strtotime($inTime);
                            $outTimestamp = strtotime($outTime);
                            if ($outTimestamp < $inTimestamp) {
                                $outTimestamp += 86400;
                            }
                            $hoursWorked = ($outTimestamp - $inTimestamp) / 3600;
                            $dailyEarnings = $hoursWorked * $salaryAmount;
                        } else {
                            // Default to 4 hours for half day
                            $dailyEarnings = 4 * $salaryAmount;
                        }
                        break;
                    case 'daily':
                        $dailyEarnings = $salaryAmount * 0.5;
                        break;
                    case 'weekly':
                        $dailyEarnings = ($salaryAmount / 7) * 0.5;
                        break;
                    case 'monthly':
                        $daysInMonth = cal_days_in_month(CAL_GREGORIAN, $month, $year);
                        $dailyEarnings = ($salaryAmount / $daysInMonth) * 0.5;
                        break;
                }
                break;

            case 'absent':
            case 'off':
                // No earnings for absent or off days
                $dailyEarnings = 0.0;
                break;
        }

        // Add overtime earnings if present (for both regular present and OT status)
        if ($status === 'present' && $overtimeHours > 0) {
            $dailyEarnings += $overtimeHours * $overtimeRate;
        }

        return $dailyEarnings;
    }
}
