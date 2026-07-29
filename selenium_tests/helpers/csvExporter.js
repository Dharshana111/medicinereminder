const fs = require('fs');
const path = require('path');
const ExcelJS = require('exceljs');

async function exportToCSV() {
  const reportsDir = path.join(__dirname, '..', 'reports');
  const xlsxPath = path.join(reportsDir, 'Latest_Test_Report.xlsx');
  const csvPath = path.join(reportsDir, 'Latest_Test_Report.csv');

  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(xlsxPath);

  const sheet = workbook.getWorksheet('All Test Cases (Detailed Log)');
  if (!sheet) {
    console.error('Worksheet not found');
    return;
  }

  const rows = [];
  sheet.eachRow((row) => {
    const rowValues = row.values.slice(1).map(val => {
      if (val === null || val === undefined) return '""';
      let str = String(val).replace(/"/g, '""');
      return `"${str}"`;
    });
    rows.push(rowValues.join(','));
  });

  fs.writeFileSync(csvPath, rows.join('\n'), 'utf-8');
  console.log(`📄 CSV Report successfully generated: ${csvPath}`);
}

exportToCSV().catch(console.error);
