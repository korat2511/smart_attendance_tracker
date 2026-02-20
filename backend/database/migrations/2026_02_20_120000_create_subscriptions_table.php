<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('razorpay_subscription_id')->unique();
            $table->string('razorpay_plan_id');
            $table->string('razorpay_customer_id')->nullable();
            $table->enum('status', [
                'created',
                'authenticated',
                'active',
                'pending',
                'halted',
                'cancelled',
                'completed',
                'expired',
                'paused'
            ])->default('created');
            $table->timestamp('trial_ends_at')->nullable();
            $table->timestamp('current_period_start')->nullable();
            $table->timestamp('current_period_end')->nullable();
            $table->integer('charge_at')->nullable();
            $table->decimal('amount', 10, 2)->default(199.00);
            $table->string('currency', 3)->default('INR');
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
