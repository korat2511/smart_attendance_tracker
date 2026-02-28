<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StaffPeriodPayment extends Model
{
    protected $table = 'staff_period_payments';

    protected $fillable = [
        'staff_id',
        'year',
        'month',
        'amount_paid',
        'payment_method',
    ];

    protected $casts = [
        'amount_paid' => 'decimal:2',
    ];

    public function staff(): BelongsTo
    {
        return $this->belongsTo(Staff::class);
    }
}
