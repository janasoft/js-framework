unit fw_resourcestrings;

{$mode objfpc}{$H+}

interface

resourcestring
rsConfirmDelete = 'Va a eliminar este registro.'+ LineEnding + LineEnding+ '¿Está seguro?';
rsError = 'Error';
rsErrSaveReg = 'Ha ocurrido un error al salvar los datos en la BD. ' +
               'El mensaje técnico es: '+ LineEnding + LineEnding + ' %s';
rsFieldsNoAct = 'La lista de Campos no contiene ningun valor. ' + LineEnding +
                'El registro no se ha actualizado.';
rsQryNoAct =  'El registro se ha almacenado correctamente, pero' + LineEnding +
              'se ha producido un error al actualizar el listado en' + LineEnding + LineEnding +
              'Campo -> %s' + LineEnding +
              'Tabla -> %s' + LineEnding + LineEnding +
              'Puede seguir trabajando, pero debe facilitar al administrador' + LineEnding +
              'el nombre del Campo y de la Tabla que han fallado';
SRegKey = '\Software\JanaSoft\Framework';
rsSaveChanges = 'Has realizado cambios en el registro. ' + LineEnding + LineEnding +
                ' ¿Quieres guardarlos?';
rsDiscardChanges = 'Has realizado cambios en el registro y no los has guardado.' + LineEnding + LineEnding +
                   'Pulsa DESCARTAR para salir de la ficha sin guardarlos.' + LineEnding +
                   'Pulsa VOLVER para continuar editando la ficha'; // + LineEnding + 'Pulsa GUARDAR para consolidar los cambios realizados';

rsErrCampoVacio = 'El campo %s no puede estar vacío';
rsInfTableOpen = 'La ventana de %s ya está abierta. ' + LineEnding
               + 'Si desea utilizarla en módo búsqueda debe cerrarla previamente. ' + LineEnding + LineEnding
               + 'Pulse ''Si'' para abrirla en modo búsqueda. ' + LineEnding
               + '¡Tenga en cuenta que puede perder las modificaciones que hubiera'
               + ' realizado en la misma! ' + LineEnding + LineEnding
               + 'Si pulsa ''No'' la ventana continuará abierta pero no podrá'
               + ' utilizarla para realizar búsquedas';
rsErrOpenSearcher = 'No se pudo determinar el nombre de la Tabla.' + LineEnding
                  + 'No es posible realizar búsquedas';
rsInfSameQuery = 'No se han modificado los parámetros de la consulta';
rsInfQueryEmpty = 'La consulta no devuelve ningún valor.' + LineEnding + LineEnding
             + '¿Desea formular otra consulta?';
rsInfTooMuchRecords = 'La consulta generada devuelve %d registros, por lo que sobrepasa '
                    + 'el número máximo de registros permitidos.' + LineEnding + LineEnding
                    + 'Pulsa ''Reformular'' para generar otra consulta'+ LineEnding + LineEnding
                    + 'Pulsa ''Ver Consulta'' para visualizar los primeros 50 registros de la consulta definida';
rsInfNotValue = 'Debe seleccionar algún valor para buscar';
rsIsBetween = 'Está entre';
rsItemsForStringSearch = '"Empieza por", "Contiene", "Es mayor que", "Es menor que", "Está entre"';
rsItemsForIntegerSearch = '"Es igual a", "Es mayor que", "es menor que", "Está entre"';


implementation

end.

