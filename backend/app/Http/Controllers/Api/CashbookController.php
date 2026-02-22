<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\CashbookIncome;
use App\Models\CashbookExpense;
use Illuminate\Http\Request;

class CashbookController extends Controller
{
    /**
     * Get monthly overview (income total, expense total, balance)
     */
    public function getOverview(Request $request)
    {
        $validated = $request->validate([
            'month' => 'required|integer|min:1|max:12',
            'year' => 'required|integer|min:2000|max:2100',
        ]);

        $userId = $request->user()->id;
        $month = $validated['month'];
        $year = $validated['year'];

        $incomeTotal = (float) CashbookIncome::withoutGlobalScope('user')
            ->where('user_id', $userId)
            ->whereYear('date', $year)
            ->whereMonth('date', $month)
            ->sum('amount');

        $expenseManual = (float) CashbookExpense::withoutGlobalScope('user')
            ->where('user_id', $userId)
            ->whereYear('date', $year)
            ->whereMonth('date', $month)
            ->sum('amount');

        $advanceTotal = (float) Attendance::withoutGlobalScope('user')
            ->whereHas('staff', fn ($q) => $q->where('user_id', $userId))
            ->whereYear('date', $year)
            ->whereMonth('date', $month)
            ->where('advance_amount', '>', 0)
            ->sum('advance_amount');

        $expenseTotal = $expenseManual + $advanceTotal;
        $balance = $incomeTotal - $expenseTotal;

        return response()->json([
            'success' => true,
            'message' => 'Overview retrieved successfully',
            'data' => [
                'month' => $month,
                'year' => $year,
                'income_total' => round($incomeTotal, 2),
                'expense_total' => round($expenseTotal, 2),
                'balance' => round($balance, 2),
            ],
        ], 200);
    }

    /**
     * Get transactions list for the month (income + expenses including advances)
     */
    public function getTransactions(Request $request)
    {
        $validated = $request->validate([
            'month' => 'required|integer|min:1|max:12',
            'year' => 'required|integer|min:2000|max:2100',
        ]);

        $userId = $request->user()->id;
        $month = $validated['month'];
        $year = $validated['year'];

        $incomes = CashbookIncome::withoutGlobalScope('user')
            ->where('user_id', $userId)
            ->whereYear('date', $year)
            ->whereMonth('date', $month)
            ->orderBy('date', 'asc')
            ->orderBy('id', 'asc')
            ->get()
            ->map(function ($row) {
                return [
                    'id' => 'income_' . $row->id,
                    'type' => 'income',
                    'date' => $row->date->format('Y-m-d'),
                    'description' => $row->description ?? 'Income',
                    'amount' => (float) $row->amount,
                ];
            });

        $expenses = CashbookExpense::withoutGlobalScope('user')
            ->where('user_id', $userId)
            ->whereYear('date', $year)
            ->whereMonth('date', $month)
            ->orderBy('date', 'asc')
            ->orderBy('id', 'asc')
            ->get()
            ->map(function ($row) {
                return [
                    'id' => 'expense_' . $row->id,
                    'type' => 'expense',
                    'date' => $row->date->format('Y-m-d'),
                    'description' => $row->description ?? 'Expense',
                    'amount' => (float) $row->amount,
                ];
            });

        $advances = Attendance::withoutGlobalScope('user')
            ->with('staff')
            ->whereHas('staff', fn ($q) => $q->where('user_id', $userId))
            ->whereYear('date', $year)
            ->whereMonth('date', $month)
            ->where('advance_amount', '>', 0)
            ->orderBy('date', 'asc')
            ->get()
            ->map(function ($attendance) {
                $staffName = $attendance->staff->name ?? 'Staff';
                return [
                    'id' => 'advance_' . $attendance->id,
                    'type' => 'expense',
                    'date' => $attendance->date->format('Y-m-d'),
                    'description' => 'Advance given to ' . $staffName,
                    'amount' => (float) $attendance->advance_amount,
                ];
            });

        $all = $incomes->concat($expenses)->concat($advances);
        $sorted = $all->sortBy(fn ($t) => $t['date'] . $t['id'])->values()->all();

        return response()->json([
            'success' => true,
            'message' => 'Transactions retrieved successfully',
            'data' => [
                'month' => $month,
                'year' => $year,
                'transactions' => $sorted,
            ],
        ], 200);
    }

    /**
     * Add income entry
     */
    public function addIncome(Request $request)
    {
        $validated = $request->validate([
            'date' => 'required|date',
            'amount' => 'required|numeric|min:0',
            'description' => 'nullable|string|max:500',
        ]);

        $income = CashbookIncome::create([
            'user_id' => $request->user()->id,
            'date' => $validated['date'],
            'amount' => $validated['amount'],
            'description' => $validated['description'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Income added successfully',
            'data' => [
                'income' => [
                    'id' => $income->id,
                    'date' => $income->date->format('Y-m-d'),
                    'amount' => (float) $income->amount,
                    'description' => $income->description,
                ],
            ],
        ], 201);
    }

    /**
     * Add expense entry
     */
    public function addExpense(Request $request)
    {
        $validated = $request->validate([
            'date' => 'required|date',
            'amount' => 'required|numeric|min:0',
            'description' => 'nullable|string|max:500',
        ]);

        $expense = CashbookExpense::create([
            'user_id' => $request->user()->id,
            'date' => $validated['date'],
            'amount' => $validated['amount'],
            'description' => $validated['description'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Expense added successfully',
            'data' => [
                'expense' => [
                    'id' => $expense->id,
                    'date' => $expense->date->format('Y-m-d'),
                    'amount' => (float) $expense->amount,
                    'description' => $expense->description,
                ],
            ],
        ], 201);
    }

    /**
     * Delete an expense entry (manual cashbook expense only; advances cannot be deleted here)
     */
    public function deleteExpense(Request $request, int $id)
    {
        $expense = CashbookExpense::withoutGlobalScope('user')
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (!$expense) {
            return response()->json([
                'success' => false,
                'message' => 'Expense not found or you do not have permission to delete it.',
            ], 404);
        }

        $expense->delete();

        return response()->json([
            'success' => true,
            'message' => 'Expense deleted successfully',
        ], 200);
    }

    /**
     * Delete an income entry
     */
    public function deleteIncome(Request $request, int $id)
    {
        $income = CashbookIncome::withoutGlobalScope('user')
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (!$income) {
            return response()->json([
                'success' => false,
                'message' => 'Income not found or you do not have permission to delete it.',
            ], 404);
        }

        $income->delete();

        return response()->json([
            'success' => true,
            'message' => 'Income deleted successfully',
        ], 200);
    }

    /**
     * Update an income entry
     */
    public function updateIncome(Request $request, int $id)
    {
        $income = CashbookIncome::withoutGlobalScope('user')
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (!$income) {
            return response()->json([
                'success' => false,
                'message' => 'Income not found or you do not have permission to update it.',
            ], 404);
        }

        $validated = $request->validate([
            'date' => 'required|date',
            'amount' => 'required|numeric|min:0',
            'description' => 'nullable|string|max:500',
        ]);

        $income->update([
            'date' => $validated['date'],
            'amount' => $validated['amount'],
            'description' => $validated['description'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Income updated successfully',
            'data' => [
                'income' => [
                    'id' => $income->id,
                    'date' => $income->date->format('Y-m-d'),
                    'amount' => (float) $income->amount,
                    'description' => $income->description,
                ],
            ],
        ], 200);
    }

    /**
     * Update an expense entry
     */
    public function updateExpense(Request $request, int $id)
    {
        $expense = CashbookExpense::withoutGlobalScope('user')
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (!$expense) {
            return response()->json([
                'success' => false,
                'message' => 'Expense not found or you do not have permission to update it.',
            ], 404);
        }

        $validated = $request->validate([
            'date' => 'required|date',
            'amount' => 'required|numeric|min:0',
            'description' => 'nullable|string|max:500',
        ]);

        $expense->update([
            'date' => $validated['date'],
            'amount' => $validated['amount'],
            'description' => $validated['description'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Expense updated successfully',
            'data' => [
                'expense' => [
                    'id' => $expense->id,
                    'date' => $expense->date->format('Y-m-d'),
                    'amount' => (float) $expense->amount,
                    'description' => $expense->description,
                ],
            ],
        ], 200);
    }
}
