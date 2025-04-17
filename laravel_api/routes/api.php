<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ClassController;

Route::middleware('api')->group(function () {
    Route::get('/classes', [ClassController::class, 'index']);
    Route::post('/classes', [ClassController::class, 'store']);
    Route::put('/classes/{id}', [ClassController::class, 'update']);
    Route::delete('/classes/{id}', [ClassController::class, 'destroy']);
});
