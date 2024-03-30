#include <cstdio>
#include <iostream>
#include <string>
#include "./dependencies/include/libpq-fe.h"
using std::cout;
using std::endl;
using std::string;
using std::cin;

#define PG_HOST "127.0.0.1"
#define PG_USER "postgres"
#define PG_PASS "password"
#define PG_PORT 5432
#define PG_DB "WinterLift"

PGconn* dbConnect(const char* host, const char* user, const char* db, const char* pass, int port) {
    char conninfo[256];
    sprintf(conninfo, "user=%s password=%s dbname=\'%s\' hostaddr=%s port=%d",
        user, pass, db, host, port);

    PGconn* conn = PQconnectdb(conninfo);

    if (PQstatus(conn) != CONNECTION_OK) {
        std::cerr << "Errore di connessione! \n" << endl << PQerrorMessage(conn);
        PQfinish(conn);
        exit(1);
    }

    return conn;
}

PGresult* executeQuery(PGconn* conn, const char* query) {
    PGresult* res = PQexec(conn, query);

    if (PQresultStatus(res) != PGRES_TUPLES_OK) {
        cout << "Risultati inconsistenti! \n" << PQerrorMessage(conn) << endl;
        PQclear(res);
        exit(1);
    }

    return res;
}

void printLine(int campi, int* maxChar) {
    for (int j = 0; j < campi; ++j) {
        cout << '+';
        for (int k = 0; k < maxChar[j] + 2; ++k)
            cout << '-';
    }
    cout << "+\n";
}

void printQuery(PGresult* result) {
    const int tuple = PQntuples(result), campi = PQnfields(result);
    string v[tuple + 1][campi];

    for (int i = 0; i < campi; ++i) {
        string s = PQfname(result, i);
        v[0][i] = s;
    }
    for (int i = 0; i < tuple; ++i)
        for (int j = 0; j < campi; ++j) {
            if (string(PQgetvalue(result, i, j)) == "t" || string(PQgetvalue(result, i, j)) == "f")
                if (string(PQgetvalue(result, i, j)) == "t")
                    v[i + 1][j] = "si";
                else
                    v[i + 1][j] = "no";
            else if(string(PQgetvalue(result, i, j)) == "")
                v[i + 1][j] = "null";
            else
                v[i + 1][j] = PQgetvalue(result, i, j);
        }

    int maxChar[campi];
    for (int i = 0; i < campi; ++i)
        maxChar[i] = 0;

    for (int i = 0; i < campi; ++i) {
        for (int j = 0; j < tuple + 1; ++j) {
            int size = v[j][i].size();
            maxChar[i] = size > maxChar[i] ? size : maxChar[i];
        }
    }

    printLine(campi, maxChar);
    for (int j = 0; j < campi; ++j) {
        cout << "| ";
        cout << v[0][j];
        for (int k = 0; k < maxChar[j] - v[0][j].size() + 1; ++k)
            cout << ' ';
        if (j == campi - 1)
            cout << "|";
    }
    cout << endl;
    printLine(campi, maxChar);

    for (int i = 1; i < tuple + 1; ++i) {
        for (int j = 0; j < campi; ++j) {
            cout << "| ";
            cout << v[i][j];
            for (int k = 0; k < maxChar[j] - v[i][j].size() + 1; ++k)
                cout << ' ';
            if (j == campi - 1)
                cout << "|";
        }
        cout << endl;
    }
    printLine(campi, maxChar);
}

char* choosePIVA(PGconn* conn) {
    PGresult* res = executeQuery(conn, "select piva from azienda");
    printQuery(res);

    const int tuple = PQntuples(res), campi = PQnfields(res);
    int val;
    cout << "Inserisci la posizione della partita iva scelta: ";
    cin >> val;
    while (val <= 0 || val > tuple) {
        cout << "Valore non valido\n";
        cout << "Inserisci la posizione della partita iva scelta: ";
        cin >> val;
    }
    return PQgetvalue(res, val - 1, 0);
}

int main(int argc, char** argv) {

    PGconn* conn = dbConnect(PG_HOST, PG_USER, PG_DB, PG_PASS, PG_PORT);

    const char* query[10] = {
        "select azienda.piva, COALESCE(sum(costo), 0) as ricavo, COALESCE(sum(data_fine - data_inizio), 0) as giorni_lavoro \
         from azienda left join manutenzione on manutenzione.azienda = azienda.piva where azienda.piva = '%s' \
         group by azienda.piva",
        
        "select proprietario, ID_tessera from tessera_sciatore join persona on tessera_sciatore.proprietario = persona.CF \
         where sesso = 'F' and data_scadenza >= CURRENT_DATE and data_scadenza < CURRENT_DATE + interval '1 month';",

        "select distinct impianto.codice, impianto.comprensorio, impianto.tipo from impianto join manutenzione  \
         on impianto.codice = manutenzione.impianto and impianto.comprensorio = manutenzione.comprensorio where \
         (manutenzione.Data_inizio >= '%s' :: date and manutenzione.Data_inizio <= '%s' :: date) or \
         (manutenzione.Data_fine >= '%s' :: date and manutenzione.Data_fine <= '%s' :: date) or \
         (manutenzione.Data_inizio < '%s' :: date and  (manutenzione.Data_fine > '%s' :: date or \
          manutenzione.Data_fine is null));",

        "drop view if exists frequentatori_comprensorio; \
         create view frequentatori_comprensorio as select comprensorio, persona from passaggio group by (comprensorio, persona); \
         select comprensorio.nome, coalesce(TRUNC(avg(extract(year from age(persona.data_nascita))), 2), null) as eta_media \
         from comprensorio left join frequentatori_comprensorio on frequentatori_comprensorio.comprensorio = comprensorio.nome \
         left join persona on frequentatori_comprensorio.persona = persona.cf group by comprensorio.nome order by eta_media asc;",

        "drop view if exists passaggi_per_giorno; \
         create view passaggi_per_giorno as \
         select passaggio.impianto, passaggio.comprensorio, date_trunc('day', passaggio.data_ora) as giorno, \
         count(*) as n_passaggi from passaggio group by passaggio.impianto, passaggio.comprensorio, giorno; \
         select impianto, comprensorio, TRUNC(avg(n_passaggi),2) as n_passaggi_medi from passaggi_per_giorno \
         group by impianto, comprensorio having avg(n_passaggi) > (select avg(n_passaggi) from passaggi_per_giorno)",

        "Select CF as codice_fiscale, Residenza from Persona Pe join Passaggio Pa on Pa.Persona = Pe.CF \
         join Impianto I on Pa.impianto = I.Codice and Pa.comprensorio = I.comprensorio where I.Provincia_impianto = Pe.residenza \
         group by Pe.CF having count(DISTINCT CONCAT(I.codice, '|', I.comprensorio)) = \
         (Select count(DISTINCT CONCAT(I2.codice, '|', I2.comprensorio)) \
         from Persona Pe2 join Passaggio Pa2 on Pe2.CF = Pa2.Persona join Impianto I2 on Pa2.impianto = I2.Codice \
         and Pa2.comprensorio = I2.comprensorio where Pe2.CF = Pe.CF);",

        "select * from (select 'Seggiovia' as Tipologia, comprensorio, impianto, N_Sedili as posti from Seggiovia S1 where \
         N_Sedili = (select max(N_Sedili) from Seggiovia S2 where S1.comprensorio = S2.comprensorio group by Comprensorio) \
         UNION select 'Cabinovia ' Tipologia, C1.comprensorio, impianto, SUM(capienza) as posti from Cabinovia C1 join \
         Cabina Cab1 on Cab1.Cabinovia = C1.impianto and Cab1.comprensorio = C1.comprensorio group by (C1.comprensorio, impianto) \
         having SUM(Capienza) = (select max(posti_) from (select SUM(capienza) as posti_ from Cabinovia C2 join \
         Cabina Cab2 on Cab2.Cabinovia = C2.impianto and Cab2.comprensorio = C2.comprensorio where \
         C1.comprensorio = C2.comprensorio group by (C2.comprensorio, impianto)) as Cabinovia_posti)) as capienza_impianti_comprensori \
         order by comprensorio",

        "select persona_utilizzi.codice_fiscale, persona_utilizzi.numero_utilizzi, TRUNC(persona_media_utilizzi.media_pax,2) as \
         media_passaggi_anno from (select persona as codice_fiscale, count(*) as numero_utilizzi from passaggio PA \
         group by PA.persona) persona_utilizzi join (select codice_fiscale, avg(pax_year) as media_pax from \
         (select persona as codice_fiscale, count(*) as pax_year from passaggio PA group by (PA.persona, EXTRACT( YEAR FROM Data_ora))) \
         as passaggi_anno_cf group by codice_fiscale) persona_media_utilizzi on persona_media_utilizzi.codice_fiscale = persona_utilizzi.codice_fiscale",

        "select codice, I.comprensorio, I.tipo, count(distinct Data_inizio), COALESCE(SUM(costo), 0) as costo_totale, \
         COALESCE(SUM(Data_fine - Data_inizio), 0) as totale_giorni from impianto I left join manutenzione M on \
         M.impianto = I.codice and M.comprensorio = I.comprensorio group by (I.codice, I.comprensorio)",

        "drop view if exists spese_gestione_per_aziende; create view spese_gestione_per_aziende as select comprensorio.nome, \
         gestione.azienda, sum(manutenzione.costo) as costi_totali, (sum(manutenzione.costo) / 100) * gestione.quota as spesa_personale \
         from manutenzione join impianto on impianto.codice = manutenzione.impianto and impianto.comprensorio = manutenzione.comprensorio \
         join comprensorio on impianto.comprensorio = comprensorio.nome join gestione on comprensorio.nome = gestione.comprensorio \
         group by (comprensorio.nome, gestione.azienda, quota); select Azienda.PIVA, \
         COALESCE(sum(spesa_personale), 0) as spesa_totale_aziendale from azienda left join spese_gestione_per_aziende \
         on azienda.piva = spese_gestione_per_aziende.azienda where azienda.PIVA = '%s' group by azienda.PIVA;",

    };

    while (true) {
        cout << endl;
        cout << "1. Una specifica azienda vuole avere un resoconto sugli interventi di manutenzione attuati sugli impianti. \n";
        cout << "   Restituire per tale azienda il totale dei ricavi e dei giorni impiegati in interventi di manutenzione. \n";
        cout << "2. Dopo un'analisi dei dati raccolti sugli impianti sciistici e' emerso che la maggior parte dei frequentatori \n";
        cout << "   sono uomini, si e' deciso dunque di inviare una promozione alle donne con tessera-sciatore in scadenza. \n";
        cout << "   Mostrare il codice fiscale e l'id della tessera-sciatore delle donne la cui tessera scade tra meno di un mese.\n";
        cout << "3. Si vuole valutare quali impianti gestiti dal sistema sono stati penalizzati da interventi di manutenzione in \n";
        cout << "   uno specifico intervallo di tempo. \n";
        cout << "   Stampare il codice, il comprensorio e il tipo degli impianti che sono stati non-operativi almeno un giorno \n";
        cout << "   all'interno di un determinato periodo.\n";
        cout << "4. Si vogliono ricavare informazioni sull'eta' dei frequentatori dei vari comprensori gestiti dal sistema. \n";
        cout << "   Mostrare per ogni comprensorio, in ordine crescente, l'eta' media degli sciatori che hanno effettuato almeno \n";
        cout << "   un passaggio negli impianti di quest'ultimo. \n";
        cout << "5. Si vogliono individuare gli impianti piu' frequentati gestiti dal sistema. \n";
        cout << "   Selezionare il codice, il comprensorio e il numero di passaggi medi per giorno degli impianti che hanno un numero\n";
        cout << "   di passaggi medi giornalieri maggiore rispetto la media dei passaggi per giorno fra tutti gli impianti.\n";
        cout << "6. Si vogliono individuare gli utenti affezionati ai soli impianti nella loro provincia di residenza. \n";
        cout << "   Mostrare il codice fiscale e la provincia di residenza delle persone che hanno eseguito almeno un passaggio \n";
        cout << "   nei soli impianti situati nella loro provincia di residenza. \n";
        cout << "7. Si vogliono visualizzare gli impianti piu' capienti per ogni comprensorio. \n";
        cout << "   Mostrare la cabinovia e la seggiovia per ogni comprensorio che possono trasportare piu' persone, \n";
        cout << "   tenendo conto del fatto che il numero di persone trasportate da una seggiovia e' pari al numeri di sedili \n";
        cout << "   di quest'ultima mentre il numero delle persone trasportate da una cabinovia e' pari alla somma della capienza \n";
        cout << "   di tutte le sue cabine.\n";
        cout << "8. Si vogliono esporre ad ogni utente dei dati interessanti sui loro utilizzi degli impianti. \n";
        cout << "   Per ogni persona restituire il numero totale di utilizzi degli impianti e la media del numero di passaggi \n";
        cout << "   per anno, tenendo conto per quest'ultima solo degli anni in cui e' stato eseguito almeno un passaggio. \n";
        cout << "9. Si vuole esibire un resoconto sugli interventi di manutenzione avvenuti sugli impianti. \n";
        cout << "   Per ogni impianto mostrare il tipo, il numero di manutenzioni fatte, il costo totale delle manutenzioni ed \n";
        cout << "   i giorni in totale non operativi. \n";
        cout << "10. Una specifica azienda vuole avere un resoconto sulle spese totali di manutenzione che ha dovuto affrontare \n";
        cout << "   in seguito alla gestione dei comprensori di cui possiede una quota. \n";
        cout << "   Mostrare il totale delle spese dell'azienda pesato sulla quote di gestione di ciascun comprensorio \n";
        cout << "Query da eseguire (0 per terminare): ";
        int q = 0;
        cin >> q;
        while (q < 0 || q > 10) {
            cout << "Le query vanno da 1 a 10...\n";
            cout << "Query da eseguire (0 per terminare): ";
            cin >> q;
        }
        if (q == 0) break;
        char queryTemp[1500];

        int i = 0;
        switch (q) {
        case 1:
            sprintf(queryTemp, query[0], choosePIVA(conn));
            printQuery(executeQuery(conn, queryTemp));
            break;
        case 3:
            char data1[11],data2[11];
            cout << "Data iniziale (AAAA-MM-GG): ";
            cin >> data1;
            cout << "Data finale (AAAA-MM-GG): ";
            cin >> data2;
            sprintf(queryTemp, query[2], data1, data2, data1, data2, data1, data2);
            printQuery(executeQuery(conn, queryTemp));
            break;
        case 10:
            sprintf(queryTemp, query[9], choosePIVA(conn));
            printQuery(executeQuery(conn, queryTemp));
            break;
        default:
            printQuery(executeQuery(conn, query[q - 1]));
            break;
        }
        system("pause");
    }

    PQfinish(conn);
}
