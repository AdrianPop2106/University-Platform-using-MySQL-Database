----------------------------------- Functionalitati student -------------------------
-- • căutare curs
-- • inscriere la curs
-- • vizualizare note
-- • vizualizare grupuri si membri
-- • mesaje pe grup
-- • vizualizare / descarcare activitati curente / din viitor

CREATE VIEW vizualizare_note AS
SELECT utilizator.nume, utilizator.prenume, cursuri.descriere, note.nota_curs , note.nota_seminar, note.nota_laborator 
FROM utilizator
JOIN student ON utilizator.utilizator_id = student.id_utilizator
JOIN inscriere_curs ON student.id_student = inscriere_curs.id_student
JOIN cursuri ON inscriere_curs.id_curs = cursuri.id_curs
JOIN note ON cursuri.id_curs = note.id_curs
GROUP BY utilizator.utilizator_id;

CREATE VIEW vizualizare_grupuri AS
SELECT grupa_studiu.nume_grup
FROM grupa_studiu
GROUP BY nume_grup;

CREATE VIEW vizualizare_mesaje AS
SELECT mesaje_grup.mesaj
FROM mesaje_grup;


DELIMITER //
CREATE PROCEDURE cautare_cursuri()
BEGIN
	select descriere from cursuri
    group by cursuri.descriere;
end; //

DELIMITER //
CREATE PROCEDURE cautare_grupuri()
BEGIN
	select nume_grup from grupa_studiu;
end; //

DELIMITER //
CREATE PROCEDURE cautare_activitati(id_grupa int)
BEGIN
	select denumire from activitate where activitate.id_grupa = id_grupa;
end; //

drop procedure inscriere_curs;
drop trigger calcul_medie;


DELIMITER //
CREATE PROCEDURE inscriere_curs(nume VARCHAR(25), id_stud INT, nr_studenti INT)
BEGIN
SET @id_curs := NULL;
SELECT @id_curs:=cursuri.ID_curs from cursuri WHERE descriere = nume AND cursuri.numar_studenti_inscrisi = nr_studenti;
INSERT INTO inscriere_curs (ID_student, ID_curs, data_inscriere) VALUES (id_stud, @id_curs, CURRENT_DATE);
update cursuri set numar_studenti_inscrisi = numar_studenti_inscrisi + 1 where id_curs = @id_curs;
END; //



DELIMITER //
CREATE PROCEDURE vizualizare_info (nume VARCHAR(25), CNP VARCHAR(25))
BEGIN
	SELECT CNP as "CNP: ", nume as "Nume: ", prenume AS "Prenume: ", adresa as "Adresa: ", IBAN as "IBAN: ", numar_telefon as "Numar de telefon: ", numar_contract as "Numar contract: ", email as "Email: "
	FROM utilizator
    WHERE utilizator.CNP = CNP;
END; //

DELIMITER //
CREATE PROCEDURE vizualizare_note (CNP VARCHAR(25))
BEGIN
	SELECT cursuri.descriere, note.nota_curs , note.nota_seminar, note.nota_laborator, note.medie 
	FROM utilizator
	JOIN student ON utilizator.utilizator_id = student.id_utilizator
	JOIN inscriere_curs ON student.id_student = inscriere_curs.id_student
	JOIN cursuri ON inscriere_curs.id_curs = cursuri.id_curs
	JOIN note ON cursuri.id_curs = note.id_curs
    WHERE CNP = utilizator.CNP
	GROUP BY cursuri.descriere;
END; //
drop trigger calcul_medie
DELIMITER //
CREATE TRIGGER calcul_medie 
BEFORE INSERT ON note
FOR EACH ROW BEGIN
     set new.medie = ((select @pondere_laborator := ponderi_note.pondere_laborator from ponderi_note where ponderi_note.id_curs = new.id_curs)/100*new.nota_laborator +
		 			(select @pondere_curs := ponderi_note.pondere_curs from ponderi_note where ponderi_note.id_curs = new.id_curs)/100*new.nota_curs +
                     (select @pondere_seminar := ponderi_note.pondere_seminar from ponderi_note where ponderi_note.id_curs = new.id_curs)/100*new.nota_seminar );
END; //
 
DELIMITER //
CREATE PROCEDURE determinare_id_student(CNP VARCHAR(25))
BEGIN 
	SELECT @stud_id := student.id_student
	FROM utilizator, student
	where utilizator.utilizator_id = student.id_utilizator
    and CNP = utilizator.CNP;  
END; //

DELIMITER //
CREATE PROCEDURE vizualizare_activitati_curente_AS_student (CNP VARCHAR(25), stud_id INT)
BEGIN
   SELECT cursuri.descriere, calendar.activitate , utilizator.nume, utilizator.prenume, calendar.zi, calendar.ora_inceput, calendar.ora_incheiere, calendar.data_inceput, calendar.data_incheiere
    from inscriere_curs
    join cursuri on inscriere_curs.id_curs = cursuri.id_curs
    join calendar on cursuri.id_curs = calendar.id_curs
    join profesor on calendar.id_profesor = profesor.id_profesor
    join utilizator on profesor.id_utilizator = utilizator.utilizator_id
    where calendar.data_inceput <= current_date and calendar.data_incheiere >= current_date
    and inscriere_curs.id_student = stud_id;
END; //

DELIMITER //
CREATE PROCEDURE vizualizare_activitati_viitoare_AS_student (CNP VARCHAR(25), stud_id INT)
BEGIN
    SELECT cursuri.descriere, calendar.activitate , utilizator.nume, utilizator.prenume, calendar.zi, calendar.ora_inceput, calendar.ora_incheiere, calendar.data_inceput, calendar.data_incheiere
    from inscriere_curs
    join cursuri on inscriere_curs.id_curs = cursuri.id_curs
    join calendar on cursuri.id_curs = calendar.id_curs
    join profesor on calendar.id_profesor = profesor.id_profesor
    join utilizator on profesor.id_utilizator = utilizator.utilizator_id
    where calendar.data_inceput > current_date
    and inscriere_curs.id_student = stud_id;
END; //


DELIMITER //
CREATE PROCEDURE vizualizare_activitati_zi_curenta_AS_student (CNP VARCHAR(25), stud_id INT)
BEGIN
    SELECT cursuri.descriere as 'Curs', calendar.activitate as 'Activitate', utilizator.nume as 'Nume profesor', utilizator.prenume as 'Prenume profesor', calendar.ora_inceput as 'Ora incepere', calendar.ora_incheiere as 'Ora terminare' 
    from inscriere_curs
    join cursuri on inscriere_curs.id_curs = cursuri.id_curs
    join calendar on cursuri.id_curs = calendar.id_curs
    join profesor on calendar.id_profesor = profesor.id_profesor
    join utilizator on profesor.id_utilizator = utilizator.utilizator_id
    where calendar.data_inceput < current_date and calendar.data_incheiere > current_date
    and calendar.zi = (SELECT dayname(current_date ))
    and inscriere_curs.id_student = stud_id;
END; //


DELIMITER //
CREATE PROCEDURE parasire_curs (CNP varchar(25), nume_curs varchar(25))
begin
	set @id := null;
    select @id:=utilizator_id from utilizator where CNP = utilizator.CNP;
    set @id_stud := null;
    select @id_stud:=student.id_student, @id_curs:=cursuri.id_curs from student, inscriere_curs, cursuri
								where student.id_student = inscriere_curs.id_student
                                and @id = student.id_utilizator
                                and inscriere_curs.id_curs = cursuri.id_curs
                                and cursuri.descriere = nume_curs;
	delete from inscriere_curs where id_student = @id_stud and id_curs = @id_curs;
	delete from note WHERE id_curs = @id_curs and id_student = @id_stud;
    UPDATE cursuri SET numar_studenti_inscrisi = numar_studenti_inscrisi - 1 WHERE cursuri.id_curs = @id_curs;
end; //


-- Grupuri

DELIMITER //
CREATE PROCEDURE scrie_mesaje (mesaj VARCHAR(100), id_student INT, nume VARCHAR(25))
BEGIN
	SET @id_gr := NULL;
    SELECT @id_gr:=grupa_studiu.ID_grupa from grupa_studiu WHERE nume_grup = nume;
	INSERT INTO mesaje_grup (mesaj, id_student, id_grupa) VALUES (mesaj, id_student, @id_gr);
END; //

DELIMITER //
CREATE PROCEDURE afiseaza_mesaje (nume_grupa VARCHAR(25))
BEGIN
	SELECT utilizator.nume, utilizator.prenume, mesaj FROM mesaje_grup, grupa_studiu, utilizator, student
    WHERE mesaje_grup.id_grupa = grupa_studiu.id_grupa
    AND nume_grupa = grupa_studiu.nume_grup
    and mesaje_grup.id_student = student.id_student
    and student.id_utilizator = utilizator.utilizator_id;
END; //

DELIMITER //
CREATE PROCEDURE vizualizare_membrii_grup (nume_grup VARCHAR(25))
BEGIN 
	SELECT utilizator.nume, utilizator.prenume 
    FROM utilizator 
    INNER JOIN student ON utilizator.utilizator_id = student.id_utilizator
    INNER JOIN membrii_grupa ON membrii_grupa.id_student = student.id_student
    INNER JOIN grupa_studiu ON grupa_studiu.id_grupa = membrii_grupa.id_grupa
    WHERE grupa_studiu.nume_grup = nume_grup;
END; //

DELIMITER //
CREATE PROCEDURE inscriere_grup(nume VARCHAR(25), CNP VARCHAR(25))   
BEGIN
    SET @id_gr := NULL;
    SELECT @id_gr:=grupa_studiu.ID_grupa from grupa_studiu WHERE nume_grup = nume;
    SET @id_stud := NULL;
    SELECT @id_stud:=id_student from student, utilizator WHERE student.id_utilizator = utilizator.utilizator_id and utilizator.CNP = CNP;
    insert into membrii_grupa(id_grupa, id_student) VALUES (@id_gr, @id_stud);
END; //

DELIMITER //
CREATE PROCEDURE parasire_grup (id_student INT, nume varchar(25))
begin
	SET @id_gr := NULL;
    SELECT @id_gr:=grupa_studiu.ID_grupa from grupa_studiu WHERE nume_grup = nume;
	delete from membrii_grupa where id_student = membrii_grupa.id_student
									and @id_gr = membrii_grupa.id_grupa;
end; //

DELIMITER //
CREATE procedure adaugare_activitate_grup(ID_grupa int, denumire varchar(25), data_organizare DATE, ora VARCHAR(25), numar_minim_participanti INT, durata_expirare INT, nume_prof VARCHAR(25))
begin
	insert into activitate (ID_grupa, denumire , data_organizare , ora , numar_minim_participanti , numar_studenti_inscrisi, durata_expirare, data_creare, profesor_implicat) values (ID_grupa, denumire, data_organizare , ora , numar_minim_participanti , 0, durata_expirare, current_time(), nume_prof);
end; //

DELIMITER //
CREATE procedure inscriere_activitate_grup(id int)
begin
	update activitate set numar_studenti_inscrisi = numar_studenti_inscrisi + 1 where id_activitate = id;
end; //   

DELIMITER //
CREATE PROCEDURE sugestii_grup(nume VARCHAR(25))
begin
	Set @id_curs:=(select ID_curs from cursuri where descriere=nume limit 1);
	SELECT utilizator.nume , utilizator.prenume 
    FROM utilizator
    INNER JOIN student ON utilizator.utilizator_id = student.id_utilizator
    WHERE student.ID_student in (select ID_student from inscriere_curs where @id_curs=ID_curs)
	and student.ID_student not in (select ID_student from membrii_grupa 
		inner join grupa_studiu on (materie_ID=@id_curs and grupa_studiu.ID_grupa=membrii_grupa.ID_grupa));
end; //

alter table `proiect`.`activitate` add column profesor_implicat varchar(25);

DELIMITER //
CREATE EVENT verificare_expirare_activitate
    ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
    DO
	BEGIN
	  SET @id_act:=(select id_activitate from activitate where (TIMEDIFF(current_time,activitate.data_creare) > activitate.durata_expirare) and activitate.numar_studenti_inscrisi < activitate.numar_minim_participanti);
      SET @id_gr:=(select id_grupa from activitate where id_activitate=@id_act);
      DELETE from activitate where id_activitate = @id_act;
      INSERT INTO mesaje_grup (mesaj, id_grupa) values ("Activitate anulata", @id_gr);
	END //   

-- ------------------------
DELIMITER //
create procedure viz_cnp(num varchar(25), prenum varchar(25))
begin
    SELECT cnp from utilizator WHERE nume = num and prenume=prenum;
end; //

DELIMITER //
create procedure viz_id(num varchar(25), prenum varchar(25))
begin
	declare id int;
    set id=(SELECT utilizator_id from utilizator WHERE nume = num and prenume=prenum);
    select id_student from student where id_utilizator=id;
end; //

DELIMITER //
create procedure viz_ore(CNP varchar(25), stud_id int)
begin
	SELECT calendar.ora_inceput as 'Ora incepere'
    from inscriere_curs
    join cursuri on inscriere_curs.id_curs = cursuri.id_curs
    join calendar on cursuri.id_curs = calendar.id_curs
    join profesor on calendar.id_profesor = profesor.id_profesor
    join utilizator on profesor.id_utilizator = utilizator.utilizator_id
    where calendar.data_inceput < current_date and calendar.data_incheiere > current_date
    and inscriere_curs.id_student = stud_id
    GROUP BY cursuri.descriere;
end; //

DELIMITER //
create procedure viz_zile(CNP varchar(25), stud_id int)
begin
	SELECT calendar.zi as 'zi'
    from inscriere_curs
    join cursuri on inscriere_curs.id_curs = cursuri.id_curs
    join calendar on cursuri.id_curs = calendar.id_curs
    join profesor on calendar.id_profesor = profesor.id_profesor
    join utilizator on profesor.id_utilizator = utilizator.utilizator_id
    where calendar.data_inceput < current_date and calendar.data_incheiere > current_date
    and inscriere_curs.id_student = stud_id
    GROUP BY cursuri.descriere;
end; //

alter table `proiect`.`activitate` add column profesor_implicat varchar(25);
