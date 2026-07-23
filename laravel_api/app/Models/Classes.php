<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Classes extends Model
{
    protected $fillable = [
        'name',
        'address',
        'email',
        'phone',
        'speciality',
        'level',
        'year',
        'semester',
        'commune_id',
    ];

    public function groups()
    {
        return $this->hasMany(Group::class);
    }
   
    public function commune()
    {
        return $this->belongsTo(Commune::class);
    }   

    public function manager()
    {
        return $this->hasOne(User::class, 'class_id')->role('manager');
    }
}
