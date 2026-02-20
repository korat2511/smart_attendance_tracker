<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Builder;

class Attendance extends Model
{
    protected $fillable = [
        'staff_id',
        'date',
        'status',
        'in_time',
        'out_time',
        'overtime_hours',
        'advance_amount',
    ];

    protected $casts = [
        'date' => 'date',
        'overtime_hours' => 'decimal:2',
        'advance_amount' => 'decimal:2',
    ];

    /**
     * Boot the model and apply global scope for multi-tenancy
     */
    protected static function booted(): void
    {
        // Global scope ensures all queries are automatically scoped to the authenticated user
        // through the staff relationship
        static::addGlobalScope('user', function (Builder $builder) {
            if (auth()->check()) {
                $builder->whereHas('staff', function ($query) {
                    $query->where('user_id', auth()->id());
                });
            }
        });
    }

    public function staff(): BelongsTo
    {
        return $this->belongsTo(Staff::class);
    }
}
