<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Staff;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AttendanceController extends Controller
{
    /**
     * Mark attendance (Present or Absent)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function markAttendance(Request $request)
    {
        $validated = $request->validate([
            'staff_id' => 'required|integer|exists:staff,id',
            'date' => 'required|date',
            'status' => ['required', 'string', Rule::in(['present', 'absent', 'off', 'half_day'])],
            'in_time' => 'nullable|date_format:H:i',
            'out_time' => 'nullable|date_format:H:i',
            'worked_hours' => 'nullable|numeric|min:0|max:24',
            'pay_multiplier' => 'nullable|numeric|min:0|max:10',
        ]);

        // Verify staff belongs to authenticated user
        $staff = Staff::where('id', $validated['staff_id'])
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        // Check if attendance already exists for this date
        $attendance = Attendance::where('staff_id', $validated['staff_id'])
            ->where('date', $validated['date'])
            ->first();

        $attendanceData = [
            'status' => $validated['status'],
            'in_time' => ($validated['status'] === 'present' || $validated['status'] === 'half_day') 
                ? ($validated['in_time'] ?? null) : null,
            'out_time' => $validated['out_time'] ?? null,
            'worked_hours' => $validated['worked_hours'] ?? 0,
            'pay_multiplier' => $validated['pay_multiplier'] ?? 1.0,
        ];

        if ($attendance) {
            $attendance->update($attendanceData);
        } else {
            $attendance = Attendance::create(array_merge([
                'staff_id' => $validated['staff_id'],
                'date' => $validated['date'],
            ], $attendanceData));
        }

        return response()->json([
            'success' => true,
            'message' => 'Attendance marked successfully',
            'data' => [
                'attendance' => [
                    'id' => $attendance->id,
                    'staff_id' => $attendance->staff_id,
                    'date' => $attendance->date->format('Y-m-d'),
                    'status' => $attendance->status,
                    'in_time' => $attendance->in_time ? date('H:i', strtotime($attendance->in_time)) : null,
                    'out_time' => $attendance->out_time ? date('H:i', strtotime($attendance->out_time)) : null,
                    'overtime_hours' => (float) $attendance->overtime_hours,
                    'worked_hours' => (float) $attendance->worked_hours,
                    'pay_multiplier' => (float) $attendance->pay_multiplier,
                    'advance_amount' => (float) $attendance->advance_amount,
                ],
            ],
        ], 200);
    }

    /**
     * Mark overtime (only if already marked as present)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function markOT(Request $request)
    {
        $validated = $request->validate([
            'staff_id' => 'required|integer|exists:staff,id',
            'date' => 'required|date',
            'overtime_hours' => 'required|numeric|min:0',
        ]);

        // Verify staff belongs to authenticated user
        $staff = Staff::where('id', $validated['staff_id'])
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        // Check if attendance exists and is marked as present
        $attendance = Attendance::where('staff_id', $validated['staff_id'])
            ->where('date', $validated['date'])
            ->first();

        if (!$attendance) {
            return response()->json([
                'success' => false,
                'message' => 'Attendance not found. Please mark attendance as present first.',
            ], 404);
        }

        if ($attendance->status !== 'present') {
            return response()->json([
                'success' => false,
                'message' => 'Overtime can only be marked for present attendance.',
            ], 400);
        }

        $attendance->update([
            'overtime_hours' => $validated['overtime_hours'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Overtime marked successfully',
            'data' => [
                'attendance' => [
                    'id' => $attendance->id,
                    'staff_id' => $attendance->staff_id,
                    'date' => $attendance->date->format('Y-m-d'),
                    'status' => $attendance->status,
                    'in_time' => $attendance->in_time ? date('H:i', strtotime($attendance->in_time)) : null,
                    'out_time' => $attendance->out_time ? date('H:i', strtotime($attendance->out_time)) : null,
                    'overtime_hours' => (float) $attendance->overtime_hours,
                    'worked_hours' => (float) $attendance->worked_hours,
                    'pay_multiplier' => (float) $attendance->pay_multiplier,
                    'advance_amount' => (float) $attendance->advance_amount,
                ],
            ],
        ], 200);
    }

    /**
     * Get attendance data for a staff member
     *
     * @param Request $request
     * @param int $staffId
     * @return \Illuminate\Http\JsonResponse
     */
    public function getAttendance(Request $request, $staffId)
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

        // Format response
        $attendanceData = $attendances->map(function ($attendance) {
            $status = $attendance->status;
            if ($status === 'present' && $attendance->overtime_hours > 0) {
                $status = 'OT'; // Overtime
            } elseif ($status === 'off') {
                $status = 'Off';
            } elseif ($status === 'present') {
                $status = 'P';
            } elseif ($status === 'half_day') {
                $status = 'HD';
            } elseif ($status === 'absent') {
                $status = 'A';
            }

            return [
                'id' => $attendance->id,
                'date' => $attendance->date->format('Y-m-d'),
                'day' => (int) $attendance->date->format('d'),
                'status' => $status,
                'in_time' => $attendance->in_time ? date('H:i', strtotime($attendance->in_time)) : null,
                'out_time' => $attendance->out_time ? date('H:i', strtotime($attendance->out_time)) : null,
                'overtime_hours' => (float) $attendance->overtime_hours,
                'worked_hours' => (float) $attendance->worked_hours,
                'pay_multiplier' => (float) $attendance->pay_multiplier,
                'advance_amount' => (float) $attendance->advance_amount,
            ];
        });

        // Calculate summary
        $presentCount = $attendances->where('status', 'present')->count();
        $absentCount = $attendances->where('status', 'absent')->count();
        $overtimeCount = $attendances->where('status', 'present')
            ->where('overtime_hours', '>', 0)
            ->count();
        $advanceTotal = $attendances->sum('advance_amount');

        return response()->json([
            'success' => true,
            'message' => 'Attendance data retrieved successfully',
            'data' => [
                'staff_id' => $staffId,
                'month' => $month,
                'year' => $year,
                'summary' => [
                    'present' => $presentCount,
                    'absent' => $absentCount,
                    'overtime' => $overtimeCount,
                    'advance_total' => (float) $advanceTotal,
                ],
                'attendances' => $attendanceData,
            ],
        ], 200);
    }

    /**
     * Mark advance payment for a date
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function markAdvance(Request $request)
    {
        $validated = $request->validate([
            'staff_id' => 'required|integer|exists:staff,id',
            'date' => 'required|date',
            'amount' => 'required|numeric|min:0',
            'notes' => 'nullable|string|max:500',
        ]);

        $staff = Staff::where('id', $validated['staff_id'])
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $attendance = Attendance::where('staff_id', $validated['staff_id'])
            ->where('date', $validated['date'])
            ->first();

        if ($attendance) {
            $attendance->update([
                'advance_amount' => $validated['amount'],
            ]);
        } else {
            $attendance = Attendance::create([
                'staff_id' => $validated['staff_id'],
                'date' => $validated['date'],
                'status' => 'absent',
                'advance_amount' => $validated['amount'],
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Advance marked successfully',
            'data' => [
                'attendance' => [
                    'id' => $attendance->id,
                    'staff_id' => $attendance->staff_id,
                    'date' => $attendance->date->format('Y-m-d'),
                    'status' => $attendance->status,
                    'in_time' => $attendance->in_time ? date('H:i', strtotime($attendance->in_time)) : null,
                    'out_time' => $attendance->out_time ? date('H:i', strtotime($attendance->out_time)) : null,
                    'overtime_hours' => (float) $attendance->overtime_hours,
                    'worked_hours' => (float) $attendance->worked_hours,
                    'pay_multiplier' => (float) $attendance->pay_multiplier,
                    'advance_amount' => (float) $attendance->advance_amount,
                ],
            ],
        ], 200);
    }
}
