const http = require('http');

function fetch(url) {
  return new Promise((resolve, reject) => {
    http.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });
}

async function main() {
  const data = await fetch('http://localhost:3000/api/timetable/weekly?branchId=1&sem=4&division=A');
  
  const batchLabs = {};
  const subjectCounts = {};
  const dayLabSlots = {};
  
  for (const day of Object.keys(data)) {
    dayLabSlots[day] = [];
    for (const slot of (data[day] || [])) {
      for (const b of (slot.batch_subjects || [])) {
        const key = b.subjectCode + '|' + b.typeOfLecture;
        if (!subjectCounts[key]) subjectCounts[key] = { lecture: 0, lab: 0 };
        
        if (b.typeOfLecture === 'Lab') {
          subjectCounts[key].lab++;
          const bk = b.batch || 'NONE';
          if (!batchLabs[bk]) batchLabs[bk] = [];
          batchLabs[bk].push(b.subjectCode + ' (' + day + ' ' + slot.startTimeHr + '-' + slot.endTimeHr + ')');
          dayLabSlots[day].push(b.subjectCode + ' batch=' + bk);
        } else {
          subjectCounts[key].lecture++;
        }
      }
    }
  }
  
  console.log('\n=== BATCH LAB DISTRIBUTION ===');
  for (const [batch, labs] of Object.entries(batchLabs)) {
    console.log('Batch ' + batch + ': ' + labs.length + ' lab entries');
    for (const l of labs) console.log('  - ' + l);
  }
  
  console.log('\n=== SUBJECT TOTALS ===');
  for (const [subj, counts] of Object.entries(subjectCounts)) {
    console.log(subj + ': ' + counts.lecture + ' lectures, ' + counts.lab + ' lab entries');
  }
  
  console.log('\n=== LABS PER DAY ===');
  for (const [day, slots] of Object.entries(dayLabSlots)) {
    console.log(day + ': ' + slots.length + ' lab entries');
  }
}

main().catch(console.error);