<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Add wilaya_id to communes
        Schema::table('communes', function (Blueprint $table) {
            $table->unsignedInteger('wilaya_id')->nullable()->after('name');
        });

        // 2. Add commune_id to classes
        Schema::table('classes', function (Blueprint $table) {
            $table->foreignId('commune_id')->nullable()->after('semester')->constrained('communes')->onDelete('cascade');
        });

        // 3. Add scoping columns to users
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedInteger('wilaya_id')->nullable()->after('role_name');
            $table->foreignId('commune_id')->nullable()->after('wilaya_id')->constrained('communes')->onDelete('set null');
            $table->foreignId('class_id')->nullable()->after('commune_id')->constrained('classes')->onDelete('set null');
            $table->foreignId('group_id')->nullable()->after('class_id')->constrained('groups')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['group_id']);
            $table->dropForeign(['class_id']);
            $table->dropForeign(['commune_id']);
            $table->dropColumn(['wilaya_id', 'commune_id', 'class_id', 'group_id']);
        });

        Schema::table('classes', function (Blueprint $table) {
            $table->dropForeign(['commune_id']);
            $table->dropColumn('commune_id');
        });

        Schema::table('communes', function (Blueprint $table) {
            $table->dropColumn('wilaya_id');
        });
    }
};
