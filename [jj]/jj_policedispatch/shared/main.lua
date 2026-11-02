local config = {
    jobsAccess = {
        "police",
        "ambulance"
    },

    radioInfo = {
        {
            zone = "especiales",
            globalFreq = 400,
            channels = {
                -- Generales
                { id = "especiales_mando",             freq = 120, name = "MANDO" },
                { id = "especiales_comisaria",         freq = 121, name = "COMISARIA" },
                { id = "especiales_asignacion",        freq = 122, name = "ESPERANDO ASIGNACION" },

                -- TAC
                { id = "especiales_tac_01",            freq = 123, name = "TAC-01" },
                { id = "especiales_tac_02",            freq = 124, name = "TAC-02" },
                { id = "especiales_tac_03",            freq = 125, name = "TAC-03" },
                { id = "especiales_tac_04",            freq = 126, name = "TAC-04" },
                { id = "especiales_tac_05",            freq = 127, name = "TAC-05" },
                { id = "especiales_tac_06",            freq = 128, name = "TAC-06" },

                -- Especiales
                { id = "especiales_control_trafico",   freq = 129, name = "CONTROL DE TRAFICO" },

                { id = "especiales_entrenamientos_01", freq = 130, name = "ENTRENAMIENTOS-01" },
                { id = "especiales_entrenamientos_02", freq = 131, name = "ENTRENAMIENTOS-02" },

                { id = "especiales_academia_10",       freq = 132, name = "ACADEMIA-10" },
                { id = "especiales_academia_20",       freq = 133, name = "ACADEMIA-20" },
                { id = "especiales_academia_30",       freq = 134, name = "ACADEMIA-30" },
                { id = "especiales_academia_40",       freq = 135, name = "ACADEMIA-40" },

                { id = "especiales_jefatura",          freq = 136, name = "JEFATURA" },
                { id = "especiales_capitania",         freq = 137, name = "CAPITANIA" },
                { id = "especiales_altos_mandos",      freq = 138, name = "ALTOS MANDOS" },
                { id = "especiales_oficiales",         freq = 139, name = "OFICIALES" },

                { id = "especiales_detective_bureau",  freq = 140, name = "DETECTIVE BUREAU" },

                { id = "especiales_of_iad",            freq = 141, name = "OF-IAD" },
                { id = "especiales_of_swat",           freq = 142, name = "OF-SWAT" },
                { id = "especiales_of_metro",          freq = 143, name = "OF-METRO" },
                { id = "especiales_of_seb",            freq = 144, name = "OF-SEB" },
                { id = "especiales_of_rtd",            freq = 145, name = "OF-RTD" },
                { id = "especiales_of_rrpp",           freq = 146, name = "OF-RRPP" },
                { id = "especiales_of_asd",            freq = 147, name = "OF-ASD" },
                { id = "especiales_of_td",             freq = 148, name = "OF-TD" },
                { id = "especiales_of_sapa",           freq = 149, name = "OF-SAPA" },
                { id = "especiales_of_k9",             freq = 150, name = "OF-K9" },
                { id = "especiales_of_marshal",        freq = 151, name = "OF-MARSHAL" },
            }
        },

        {
            zone = "lspd",
            globalFreq = 400,
            channels = {
                { id = "lspd_adam_10",    freq = 152, name = "ADAM-10" },
                { id = "lspd_adam_20",    freq = 153, name = "ADAM-20" },
                { id = "lspd_adam_30",    freq = 154, name = "ADAM-30" },
                { id = "lspd_adam_40",    freq = 155, name = "ADAM-40" },
                { id = "lspd_adam_50",    freq = 156, name = "ADAM-50" },
                { id = "lspd_adam_60",    freq = 157, name = "ADAM-60" },
                { id = "lspd_adam_70",    freq = 158, name = "ADAM-70" },
                { id = "lspd_adam_80",    freq = 159, name = "ADAM-80" },
                { id = "lspd_adam_90",    freq = 160, name = "ADAM-90" },

                { id = "lspd_mary_10",    freq = 161, name = "MARY-10" },
                { id = "lspd_mary_20",    freq = 162, name = "MARY-20" },
                { id = "lspd_mary_30",    freq = 163, name = "MARY-30" },

                { id = "lspd_lincoln_10", freq = 164, name = "LINCOLN-10" },
                { id = "lspd_lincoln_20", freq = 165, name = "LINCOLN-20" },
                { id = "lspd_lincoln_30", freq = 166, name = "LINCOLN-30" },
                { id = "lspd_lincoln_40", freq = 167, name = "LINCOLN-40" },
                { id = "lspd_lincoln_50", freq = 168, name = "LINCOLN-50" },

                { id = "lspd_king_10",    freq = 169, name = "KING-10" },
                { id = "lspd_king_20",    freq = 170, name = "KING-20" },
                { id = "lspd_king_30",    freq = 171, name = "KING-30" },
                { id = "lspd_king_40",    freq = 172, name = "KING-40" },

                { id = "lspd_tom_10",     freq = 173, name = "TOM-10" },
                { id = "lspd_tom_20",     freq = 174, name = "TOM-20" },
                { id = "lspd_tom_30",     freq = 175, name = "TOM-30" },
                { id = "lspd_tom_40",     freq = 176, name = "TOM-40" },
                { id = "lspd_tom_50",     freq = 177, name = "TOM-50" },
                { id = "lspd_tom_60",     freq = 178, name = "TOM-60" },
                { id = "lspd_tom_70",     freq = 179, name = "TOM-70" },

                { id = "lspd_pegaso_10",  freq = 180, name = "PEGASO-10" },
                { id = "lspd_pegaso_20",  freq = 181, name = "PEGASO-20" },

                { id = "lspd_david_20",   freq = 182, name = "DAVID-20" },
                { id = "lspd_david_30",   freq = 183, name = "DAVID-30" },
                { id = "lspd_david_40",   freq = 184, name = "DAVID-40" },

                { id = "lspd_marshal_10", freq = 185, name = "MARSHAL-10" },
                { id = "lspd_marshal_20", freq = 186, name = "MARSHAL-20" },

                { id = "lspd_sea_10",     freq = 187, name = "SEA-10" },
                { id = "lspd_public_10",  freq = 188, name = "PUBLIC-10" },
            }
        },

        {
            zone = "lssd",
            globalFreq = 400,
            channels = {
                { id = "lssd_bravo_10",  freq = 189, name = "BRAVO-10" },
                { id = "lssd_bravo_20",  freq = 190, name = "BRAVO-20" },
                { id = "lssd_bravo_30",  freq = 191, name = "BRAVO-30" },
                { id = "lssd_bravo_40",  freq = 192, name = "BRAVO-40" },
                { id = "lssd_bravo_50",  freq = 193, name = "BRAVO-50" },

                { id = "lssd_henry_40",  freq = 194, name = "HENRY-40" },
                { id = "lssd_henry_50",  freq = 195, name = "HENRY-50" },
                { id = "lssd_henry_60",  freq = 196, name = "HENRY-60" },

                { id = "lssd_king_40",   freq = 197, name = "KING-40" },
                { id = "lssd_king_50",   freq = 198, name = "KING-50" },
                { id = "lssd_king_60",   freq = 199, name = "KING-60" },

                { id = "lssd_tet_10",    freq = 200, name = "TET-10" },
                { id = "lssd_tet_20",    freq = 201, name = "TET-20" },

                { id = "lssd_tango_10",  freq = 202, name = "TANGO-10" },
                { id = "lssd_tango_20",  freq = 203, name = "TANGO-20" },

                { id = "lssd_aguila_10", freq = 204, name = "AGUILA-10" },

                { id = "lssd_lima_10",   freq = 205, name = "LIMA-10" },
                { id = "lssd_lima_20",   freq = 206, name = "LIMA-20" },
                { id = "lssd_lima_30",   freq = 207, name = "LIMA-30" },
                { id = "lssd_lima_40",   freq = 208, name = "LIMA-40" },
            }
        },

        {
            zone = "safmd",
            globalFreq = 700,
            channels = {
                { id = "safmd_central_emergencias", freq = 209, name = "CENTRAL DE EMERGENCIAS" },
                { id = "safmd_asignacion",          freq = 210, name = "A LA ESPERA DE ASIGNACION" },
                { id = "safmd_jefatura",            freq = 211, name = "JEFATURA SAFMD" },
                { id = "safmd_hospital",            freq = 212, name = "HOSPITAL" },

                { id = "safmd_consulta_1",          freq = 213, name = "CONSULTA 1" },
                { id = "safmd_consulta_2",          freq = 214, name = "CONSULTA 2" },

                { id = "safmd_quirofano_1",         freq = 215, name = "QUIROFANO 1" },
                { id = "safmd_quirofano_2",         freq = 216, name = "QUIROFANO 2" },

                { id = "safmd_cafeteria",           freq = 217, name = "CAFETERIA SAFMD" },

                { id = "safmd_ambulancia_10",       freq = 218, name = "AMBULANCIA-10" },
                { id = "safmd_ambulancia_20",       freq = 219, name = "AMBULANCIA-20" },
                { id = "safmd_ambulancia_30",       freq = 220, name = "AMBULANCIA-30" },
                { id = "safmd_ambulancia_40",       freq = 221, name = "AMBULANCIA-40" },
                { id = "safmd_ambulancia_50",       freq = 222, name = "AMBULANCIA-50" },

                { id = "safmd_unidad_veterinaria",  freq = 223, name = "UNIDAD DE VETERINARIA" },
                { id = "safmd_unidad_forense",      freq = 224, name = "UNIDAD DE FORENSE" },

                { id = "safmd_rescate_1",           freq = 225, name = "UNIDAD DE RESCATE 1" },
                { id = "safmd_rescate_2",           freq = 226, name = "UNIDAD DE RESCATE 2" },

                { id = "safmd_tac_1_eventos",       freq = 227, name = "TAC-1 (EVENTOS Y/O PRACTICAS)" },
                { id = "safmd_tac_2_eventos",       freq = 228, name = "TAC-2 (EVENTOS Y/O PRACTICAS)" },

                { id = "safmd_academia_1",          freq = 229, name = "ACADEMIA-SAFMD 1" },
            }
        }
    }
}

return config