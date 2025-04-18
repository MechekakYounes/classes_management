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
    
    public function class()
    {
        return $this->belongsTo(Classes::class, 'class_id');
    }
}
