<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
class Group extends Model
{
    use HasFactory;
    
    protected $table = 'grp'; // <-- Add this line
    
    protected $fillable = [
        'id',
        'name',
        'type',
        'class_id'
    ];
<<<<<<< HEAD
    
    public function class()
    {
        return $this->belongsTo(Classes::class, 'class_id');
    }
=======


    public function classes()
{
    return $this->belongsTo(Classes::class);
}

>>>>>>> 3c641c4b476c5178c927d14691c05ec676d1b318
}
