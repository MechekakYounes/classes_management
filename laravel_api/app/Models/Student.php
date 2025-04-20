<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    protected $fillable = [
        'fname',
        'name',
        'group_id'
    ];


    public function groups()
{
    return $this->belongsTo(Group::class);
}

}
