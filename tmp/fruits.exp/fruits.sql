{ DATABASE fruits  delimiter | }

grant dba to "genero";











{ TABLE "genero".fruits row size = 158 number of columns = 5 index size = 65 }

{ unload file name = fruit00100.unl number of rows = 10 }

create table "genero".fruits 
  (
    entryid serial not null ,
    fruit_name varchar(50) not null ,
    variety varchar(50),
    color varchar(30),
    season varchar(20),
    unique (fruit_name)  constraint "genero".uq_fruits_name,
    primary key (entryid)  constraint "genero".pk_fruits
  );

revoke all on "genero".fruits from "public" as "genero";

{ TABLE "genero".vendors row size = 178 number of columns = 5 index size = 65 }

{ unload file name = vendo00101.unl number of rows = 10 }

create table "genero".vendors 
  (
    entryid serial not null ,
    vendor_name varchar(50) not null ,
    contact_name varchar(50),
    phone varchar(20),
    email varchar(50),
    unique (vendor_name)  constraint "genero".uq_vendors_name,
    primary key (entryid)  constraint "genero".pk_vendors
  );

revoke all on "genero".vendors from "public" as "genero";

{ TABLE "genero".fruits_by_vendor row size = 17 number of columns = 4 index size = 40 }

{ unload file name = fruit00102.unl number of rows = 5 }

create table "genero".fruits_by_vendor 
  (
    entryid serial not null ,
    fruit_id integer not null ,
    vendor_id integer not null ,
    price decimal(8,2),
    unique (fruit_id,vendor_id)  constraint "genero".uq_fbv_fruit_vendor,
    primary key (entryid)  constraint "genero".pk_fruits_by_vendor
  );

revoke all on "genero".fruits_by_vendor from "public" as "genero";




grant select on "genero".fruits to "public" as "genero";
grant update on "genero".fruits to "public" as "genero";
grant insert on "genero".fruits to "public" as "genero";
grant delete on "genero".fruits to "public" as "genero";
grant index on "genero".fruits to "public" as "genero";
grant select on "genero".vendors to "public" as "genero";
grant update on "genero".vendors to "public" as "genero";
grant insert on "genero".vendors to "public" as "genero";
grant delete on "genero".vendors to "public" as "genero";
grant index on "genero".vendors to "public" as "genero";
grant select on "genero".fruits_by_vendor to "public" as "genero";
grant update on "genero".fruits_by_vendor to "public" as "genero";
grant insert on "genero".fruits_by_vendor to "public" as "genero";
grant delete on "genero".fruits_by_vendor to "public" as "genero";
grant index on "genero".fruits_by_vendor to "public" as "genero";












CREATE PROCEDURE "genero".fn_delete_fruit_cascade(p_fruit_id INTEGER)

    DELETE FROM fruits_by_vendor
    WHERE fruit_id = p_fruit_id;

END PROCEDURE;





grant  execute on procedure "genero".fn_delete_fruit_cascade (integer) to "public" as "genero";


revoke usage on language SPL from public ;

grant usage on language SPL to public ;








alter table "genero".fruits_by_vendor add constraint (foreign 
    key (fruit_id) references "genero".fruits  constraint "genero"
    .fk_fbv_fruit);
alter table "genero".fruits_by_vendor add constraint (foreign 
    key (vendor_id) references "genero".vendors  constraint "genero"
    .fk_fbv_vendor);



create trigger "genero".trg_fruits_cascade_delete delete on "genero"
    .fruits referencing old as pre
    for each row
        (
        execute procedure "genero".fn_delete_fruit_cascade(pre.entryid 
    ));





 



