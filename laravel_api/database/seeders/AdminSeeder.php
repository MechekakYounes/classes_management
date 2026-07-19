<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Commune;
use App\Models\Classes;
use App\Models\Group;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Create default administrative records
        $commune = Commune::create([
            'name' => 'الجزائر الوسطى',
            'wilaya_id' => 16, // Algiers
        ]);

        $school = Classes::create([
            'name' => 'مدرسة النخبة الوطنية',
            'speciality' => 'علوم تجريبية',
            'level' => 'ثانوي',
            'year' => '2026',
            'semester' => 'الفصل الأول',
            'commune_id' => $commune->id,
        ]);

        $group = Group::create([
            'name' => 'الفوج الأول (أ)',
            'type' => 'TD',
            'class_id' => $school->id,
        ]);

        // 2. Create users with different scoped roles

        // Super Admin (المشرف الوطني الشامل)
        User::create([
            'name' => 'المشرف العام الوطني',
            'username' => 'superadmin',
            'password' => bcrypt('superadmin'),
            'phone' => '0555000001',
            'is_active' => true,
            'role_name' => 'super-admin',
        ])->assignRole('super-admin');

        // Admin (المشرف الولائي - Algiers Wilaya 16)
        User::create([
            'name' => 'مشرف ولاية الجزائر',
            'username' => 'admin',
            'password' => bcrypt('admin'),
            'phone' => '0555000002',
            'is_active' => true,
            'role_name' => 'admin',
            'wilaya_id' => 16,
        ])->assignRole('admin');

        // Supervisor (المشرف البلدي - Alger Centre Commune)
        User::create([
            'name' => 'مشرف بلدية الجزائر الوسطى',
            'username' => 'supervisor',
            'password' => bcrypt('supervisor'),
            'phone' => '0555000003',
            'is_active' => true,
            'role_name' => 'supervisor',
            'wilaya_id' => 16,
            'commune_id' => $commune->id,
        ])->assignRole('supervisor');

        // Manager (مدير المدرسة)
        User::create([
            'name' => 'مدير مدرسة النخبة',
            'username' => 'manager',
            'password' => bcrypt('manager'),
            'phone' => '0555000004',
            'is_active' => true,
            'role_name' => 'manager',
            'wilaya_id' => 16,
            'commune_id' => $commune->id,
            'class_id' => $school->id,
        ])->assignRole('manager');

        // Teacher (المدرس)
        User::create([
            'name' => 'الأستاذ أحمد',
            'username' => 'teacher',
            'password' => bcrypt('teacher'),
            'phone' => '0555000005',
            'is_active' => true,
            'role_name' => 'teacher',
            'wilaya_id' => 16,
            'commune_id' => $commune->id,
            'class_id' => $school->id,
            'group_id' => $group->id,
        ])->assignRole('teacher');
    }
}
