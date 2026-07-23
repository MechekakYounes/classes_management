<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Make legacy non-nullable columns nullable.
     */
    public function up(): void
    {
        Schema::table('classes', function (Blueprint $table) {
            $table->string('year')->nullable()->change();
            $table->string('speciality')->nullable()->change();
            $table->string('level')->nullable()->change();
            $table->string('semester')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('classes', function (Blueprint $table) {
            $table->string('year')->nullable(false)->change();
        });
    }
};
