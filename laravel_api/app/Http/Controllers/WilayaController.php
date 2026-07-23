<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Wilaya;

class WilayaController extends Controller
{
    public function index()
    {
        return response()->json(Wilaya::all());
    }
}
