<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\StaffController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\CashbookController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Health check endpoint
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'message' => 'API is running',
        'timestamp' => now()->toIso8601String(),
    ]);
});

// API Version 1 routes
Route::prefix('v1')->group(function () {
    
    // Public routes (no authentication required)
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/register', [AuthController::class, 'signup']);
    
    // Protected routes (authentication required)
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/auth/me', [AuthController::class, 'me']);
        
        // Staff routes
        Route::prefix('staff')->group(function () {
            Route::get('/', [StaffController::class, 'index']);
            Route::get('/{id}', [StaffController::class, 'show']);
            Route::post('/', [StaffController::class, 'store']);
            Route::put('/{id}', [StaffController::class, 'update']);
            Route::delete('/{id}', [StaffController::class, 'destroy']);
        });
        
        // Attendance routes
        Route::prefix('attendance')->group(function () {
            Route::post('/mark', [AttendanceController::class, 'markAttendance']);
            Route::post('/mark-ot', [AttendanceController::class, 'markOT']);
            Route::post('/advance', [AttendanceController::class, 'markAdvance']);
            Route::get('/staff/{staffId}', [AttendanceController::class, 'getAttendance']);
        });
        
        // Report routes
        Route::prefix('report')->group(function () {
            Route::get('/labor/{staffId}', [ReportController::class, 'getLaborReport']);
        });

        // Cashbook routes (income, expenses; advances appear as expenses automatically)
        Route::prefix('cashbook')->group(function () {
            Route::get('/overview', [CashbookController::class, 'getOverview']);
            Route::get('/transactions', [CashbookController::class, 'getTransactions']);
            Route::post('/income', [CashbookController::class, 'addIncome']);
            Route::post('/expense', [CashbookController::class, 'addExpense']);
        });
        
        // Profile routes
        Route::prefix('profile')->group(function () {
            Route::get('/', function () {
                return response()->json(['message' => 'Get profile - to be implemented'], 200);
            });
            
            Route::put('/update', function () {
                return response()->json(['message' => 'Update profile - to be implemented'], 200);
            });
        });
    });
});
