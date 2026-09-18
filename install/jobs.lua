--[[
    ══════════════════════════════════════════════════════════════
    الفرسان RP — تعريفات الوظائف (Jobs)
    ══════════════════════════════════════════════════════════════
    ضع محتوى هذا الملف داخل: qb-core/shared/jobs.lua
    (أو أضِفه بعد جدول QBCore.Shared.Jobs الأصلي)
    ══════════════════════════════════════════════════════════════
]]

local JOBS = {
    unemployed = {
        label = "بلا عمل", type = "none", defaultDuty = true, offDutyPay = false,
        grades = { ['0'] = { name = 'بلا عمل', payment = 0 } },
    },
    miner = {
        label = "عامل منجم", type = "miner", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متدرّب',      payment = 260 },
            ['1'] = { name = 'عامل منجم',   payment = 320 },
            ['2'] = { name = 'خبير تعدين',  payment = 400 },
            ['3'] = { name = 'مشرف مقلع',   payment = 520 },
            ['4'] = { name = 'مدير المنجم', payment = 680 },
        },
    },
    carpenter = {
        label = "نجار", type = "carpenter", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متدرّب',      payment = 280 },
            ['1'] = { name = 'نجّار',       payment = 340 },
            ['2'] = { name = 'خبير',        payment = 420 },
            ['3'] = { name = 'رئيس ورشة',   payment = 540 },
            ['4'] = { name = 'مدير النجارة', payment = 700 },
        },
    },
    blacksmith = {
        label = "حداد", type = "blacksmith", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متدرّب',      payment = 300 },
            ['1'] = { name = 'حدّاد',       payment = 380 },
            ['2'] = { name = 'خبير',        payment = 480 },
            ['3'] = { name = 'كبير الصاغة', payment = 620 },
            ['4'] = { name = 'رئيس الورشة', payment = 780 },
        },
    },
    mechanic = {
        label = "ميكانيكي", type = "mechanic", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متدرّب',        payment = 320 },
            ['1'] = { name = 'ميكانيكي',      payment = 420 },
            ['2'] = { name = 'فنّي',          payment = 540 },
            ['3'] = { name = 'مهندس',         payment = 680 },
            ['4'] = { name = 'مدير الورشة',   payment = 850 },
        },
    },
    electrician = {
        label = "كهربائي", type = "electrician", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متدرّب', payment = 300 },
            ['1'] = { name = 'فنّي',    payment = 380 },
            ['2'] = { name = 'مهندس',   payment = 500 },
            ['3'] = { name = 'رئيس قسم', payment = 660 },
        },
    },
    water = {
        label = "عامل مياه", type = "water", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متدرّب',    payment = 280 },
            ['1'] = { name = 'فنّي مياه', payment = 360 },
            ['2'] = { name = 'مهندس',     payment = 480 },
        },
    },
    garbage = {
        label = "عامل نظافة", type = "garbage", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متدرّب',      payment = 200 },
            ['1'] = { name = 'عامل نظافة',  payment = 260 },
            ['2'] = { name = 'مشرف موقع',   payment = 340 },
        },
    },
    fisher = {
        label = "صياد", type = "fisher", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متدرّب',     payment = 240 },
            ['1'] = { name = 'صياد',       payment = 320 },
            ['2'] = { name = 'صياد ماهر',  payment = 420 },
            ['3'] = { name = 'سيد البحر',  payment = 560 },
        },
    },
    oilworker = {
        label = "عامل نفط", type = "oil", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متدرّب',     payment = 340 },
            ['1'] = { name = 'عامل حقل',   payment = 440 },
            ['2'] = { name = 'فنّي مصفاة', payment = 560 },
            ['3'] = { name = 'بارون النفط', payment = 720 },
        },
    },
    trucker = {
        label = "سائق شاحنات", type = "trucker", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متدرّب',       payment = 300 },
            ['1'] = { name = 'سائق',         payment = 400 },
            ['2'] = { name = 'سائق محترف',   payment = 520 },
            ['3'] = { name = 'ملك الطريق',   payment = 660 },
        },
    },
    farmer = {
        label = "مزارع", type = "farmer", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'فلاح جديد',  payment = 240 },
            ['1'] = { name = 'مزارع',       payment = 320 },
            ['2'] = { name = 'فلاح خبير',   payment = 440 },
            ['3'] = { name = 'سيد الحقول',  payment = 580 },
        },
    },
    dealer = {
        label = "بائع مركبات", type = "dealer", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متعاون',    payment = 320 },
            ['1'] = { name = 'بائع',      payment = 440 },
            ['2'] = { name = 'بائع أول',  payment = 580 },
            ['3'] = { name = 'مدير معرض', payment = 760 },
        },
    },
    taxi = {
        label = "سائق تاكسي", type = "taxi", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متعاون', payment = 240 },
            ['1'] = { name = 'سائق',   payment = 320 },
            ['2'] = { name = 'ناقل',   payment = 400 },
        },
    },
    realestate = {
        label = "وسيط عقاري", type = "realestate", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متعاون',    payment = 360 },
            ['1'] = { name = 'وسيط',      payment = 500 },
            ['2'] = { name = 'وسيط أول',  payment = 680 },
            ['3'] = { name = 'بارون العقار', payment = 900 },
        },
    },
    police = {
        label = "الأمن العام", type = "leo", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'مجنّد',       payment = 450 },
            ['1'] = { name = 'شرطي',        payment = 520 },
            ['2'] = { name = 'عريف',        payment = 600 },
            ['3'] = { name = 'رقيب',        payment = 700 },
            ['4'] = { name = 'ملازم',       payment = 820, isboss = true },
            ['5'] = { name = 'نقيب',        payment = 960 },
            ['6'] = { name = 'رائد',        payment = 1120 },
            ['7'] = { name = 'عقيد',        payment = 1300 },
            ['8'] = { name = 'القائد العام', payment = 1600, isboss = true },
        },
    },
    ambulance = {
        label = "الإسعاف", type = "ems", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متدرّب',     payment = 425 },
            ['1'] = { name = 'مسعف',       payment = 500 },
            ['2'] = { name = 'مسعف أول',   payment = 580 },
            ['3'] = { name = 'طبيب',       payment = 700, isboss = true },
            ['4'] = { name = 'مدير المستشفى', payment = 900, isboss = true },
        },
    },
    judge = {
        label = "القضاء", type = "judge", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'كاتب عدل', payment = 700 },
            ['1'] = { name = 'قاضي',     payment = 1100 },
            ['2'] = { name = 'رئيس المحكمة', payment = 1500, isboss = true },
        },
    },
    lawyer = {
        label = "محامي", type = "lawyer", defaultDuty = true, offDutyPay = false,
        grades = {
            ['0'] = { name = 'متدرب',       payment = 400 },
            ['1'] = { name = 'محامي',       payment = 600 },
            ['2'] = { name = 'محامي أول',   payment = 850 },
            ['3'] = { name = 'شريك',        payment = 1200, isboss = true },
        },
    },
}

if QBCore and QBCore.Shared then
    for k, v in pairs(JOBS) do
        QBCore.Shared.Jobs[k] = v
    end
end

return JOBS
