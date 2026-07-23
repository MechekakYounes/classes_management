<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;
use Illuminate\Notifications\Notifiable;


class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, HasRoles;

    protected $fillable = [
        'name',
        'username',
        'password',
        'phone',
        'is_active',
        'wilaya_id',
        'commune_id',
        'class_id',
        'group_id',
    ];

    protected $appends = [
        'wilaya_name',
        'commune_name',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'password' => 'hashed',
        'is_active' => 'boolean',
    ];

     public function isActive(): bool
    {
        return $this->is_active;
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeSearch($query, $search)
    {
        return $query
            ->where('name', 'like', "%{$search}%")
            ->orWhere('username', 'like', "%{$search}%")
            ->orWhere('phone', 'like', "%{$search}%");
    }

    public function wilaya()
    {
        return $this->belongsTo(Wilaya::class);
    }

    public function commune()
    {
        return $this->belongsTo(Commune::class);
    }

    public function class()
    {
        return $this->belongsTo(Classes::class, 'class_id');
    }

    public function group()
    {
        return $this->belongsTo(Group::class, 'group_id');
    }

    public function getWilayaNameAttribute()
    {
        return $this->wilaya ? $this->wilaya->name : null;
    }

    public function getCommuneNameAttribute()
    {
        return $this->commune ? $this->commune->name : null;
    }
}