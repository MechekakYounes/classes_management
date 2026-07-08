<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Commune extends Model
{
   protected $table = 'communes';
   protected $fillable = [
       'name',
   ];

   public function classes()
   {
       return $this->hasMany(Classes::class);
   }
   
}
