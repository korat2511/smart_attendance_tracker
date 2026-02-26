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
        Schema::table('cashbook_income', function (Blueprint $table) {
            $table->string('payment_method', 50)->nullable()->after('description');
        });

        Schema::table('cashbook_expense', function (Blueprint $table) {
            $table->string('payment_method', 50)->nullable()->after('description');
        });

        Schema::table('attendances', function (Blueprint $table) {
            $table->string('advance_payment_method', 50)->nullable()->after('advance_amount');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('cashbook_income', function (Blueprint $table) {
            $table->dropColumn('payment_method');
        });

        Schema::table('cashbook_expense', function (Blueprint $table) {
            $table->dropColumn('payment_method');
        });

        Schema::table('attendances', function (Blueprint $table) {
            $table->dropColumn('advance_payment_method');
        });
    }
};
