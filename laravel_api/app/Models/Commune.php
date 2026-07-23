<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Commune extends Model
{
   protected $table = 'communes';
   protected $fillable = [
       'name',
       'wilaya_id',
   ];


   public function classes()
   {
       return $this->hasMany(Classes::class);
   }

   public function wilaya()
   {
       return $this->belongsTo(Wilaya::class);
   }
}
