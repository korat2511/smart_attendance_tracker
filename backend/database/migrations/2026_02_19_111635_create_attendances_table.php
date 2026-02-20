<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('attendances', function (Blueprint $table) {
            $table->id();
            $table->foreignId('staff_id')->constrained('staff')->onDelete('cascade');
            $table->date('date');
            $table->enum('status', ['present', 'absent', 'off'])->default('present');
            $table->time('in_time')->nullable();
            $table->time('out_time')->nullable();
            $table->decimal('overtime_hours', 5, 2)->default(0);
            $table->decimal('advance_amount', 10, 2)->default(0);
            $table->timestamps();

            // Ensure one attendance record per staff per date
            $table->unique(['staff_id', 'date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attendances');
    }
};
