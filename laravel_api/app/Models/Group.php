<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Group extends Model
{
    protected $fillable = [
        'name',
        'type',
        'type_age',
        'gender',
        'class_id'
    ];


public function classes()
{
    return $this->belongsTo(Classes::class, 'class_id');
}

public function students()
{
    return $this->hasMany(Student::class);
}

}
