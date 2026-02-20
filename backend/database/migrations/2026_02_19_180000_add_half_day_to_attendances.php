<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Modify the enum column to include 'half_day'
        DB::statement("ALTER TABLE attendances MODIFY COLUMN status ENUM('present', 'absent', 'off', 'half_day') DEFAULT 'present'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revert back to original enum values
        DB::statement("ALTER TABLE attendances MODIFY COLUMN status ENUM('present', 'absent', 'off') DEFAULT 'present'");
    }
};
