<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        user::create([
            'name' => 'Admin',
            'username' => 'admin',
            'password' => bcrypt('admin'),
            'phone' => '1234567890',
            'is_active' => true,
        ])->assignRole('super-admin');
    }
}
