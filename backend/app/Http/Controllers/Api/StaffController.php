<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Staff;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class StaffController extends Controller
{
    /**
     * Get all staff members for the authenticated user (business owner)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        // Global scope automatically filters by user_id, so we can safely get all staff
        $staff = Staff::orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Staff members retrieved successfully',
            'data' => [
                'staff' => $staff->map(function ($member) {
                    return [
                        'id' => $member->id,
                        'name' => $member->name,
                        'phone_number' => $member->phone_number,
                        'salary_type' => $member->salary_type,
                        'salary_amount' => (float) $member->salary_amount,
                        'overtime_charges' => (float) $member->overtime_charges,
                        'created_at' => $member->created_at->toIso8601String(),
                        'updated_at' => $member->updated_at->toIso8601String(),
                    ];
                }),
                'total' => $staff->count(),
            ],
        ], 200);
    }

    /**
     * Get a single staff member by ID
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Request $request, $id)
    {
        // Global scope ensures user can only access their own staff
        $staff = Staff::findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => 'Staff member retrieved successfully',
            'data' => [
                'staff' => [
                    'id' => $staff->id,
                    'name' => $staff->name,
                    'phone_number' => $staff->phone_number,
                    'salary_type' => $staff->salary_type,
                    'salary_amount' => (float) $staff->salary_amount,
                    'overtime_charges' => (float) $staff->overtime_charges,
                    'created_at' => $staff->created_at->toIso8601String(),
                    'updated_at' => $staff->updated_at->toIso8601String(),
                ],
            ],
        ], 200);
    }

    /**
     * Create a new staff member
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'phone_number' => 'required|string|max:20',
            'salary_type' => ['required', 'string', Rule::in(['hourly', 'daily', 'weekly', 'monthly'])],
            'salary_amount' => 'required|numeric|min:0',
            'overtime_charges' => 'nullable|numeric|min:0',
        ]);

        $staff = Staff::create([
            'user_id' => $request->user()->id,
            'name' => $validated['name'],
            'phone_number' => $validated['phone_number'],
            'salary_type' => $validated['salary_type'],
            'salary_amount' => $validated['salary_amount'],
            'overtime_charges' => $validated['overtime_charges'] ?? 0,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Staff member created successfully',
            'data' => [
                'staff' => [
                    'id' => $staff->id,
                    'name' => $staff->name,
                    'phone_number' => $staff->phone_number,
                    'salary_type' => $staff->salary_type,
                    'salary_amount' => (float) $staff->salary_amount,
                    'overtime_charges' => (float) $staff->overtime_charges,
                    'created_at' => $staff->created_at->toIso8601String(),
                ],
            ],
        ], 201);
    }

    /**
     * Update a staff member
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, $id)
    {
        $staff = Staff::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'phone_number' => 'sometimes|required|string|max:20',
            'salary_type' => ['sometimes', 'required', 'string', Rule::in(['hourly', 'daily', 'weekly', 'monthly'])],
            'salary_amount' => 'sometimes|required|numeric|min:0',
            'overtime_charges' => 'nullable|numeric|min:0',
        ]);

        $staff->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Staff member updated successfully',
            'data' => [
                'staff' => [
                    'id' => $staff->id,
                    'name' => $staff->name,
                    'phone_number' => $staff->phone_number,
                    'salary_type' => $staff->salary_type,
                    'salary_amount' => (float) $staff->salary_amount,
                    'overtime_charges' => (float) $staff->overtime_charges,
                    'updated_at' => $staff->updated_at->toIso8601String(),
                ],
            ],
        ], 200);
    }

    /**
     * Delete a staff member
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Request $request, $id)
    {
        // Global scope ensures user can only delete their own staff
        $staff = Staff::findOrFail($id);
        $staff->delete();

        return response()->json([
            'success' => true,
            'message' => 'Staff member deleted successfully',
        ], 200);
    }
}
