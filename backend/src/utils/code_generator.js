/**
 * Tự động sinh mã phiếu khám duy nhất theo cấu trúc: MB-YYYYMMDD-XXX
 * @param {number} sequence Số thứ tự giao dịch trong ngày
 */
function generateBookingCode(sequence = 1) {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const randomSuffix = Math.floor(100 + Math.random() * 900); // 3 chữ số ngẫu nhiên
  const seqStr = String(sequence).padStart(3, '0');
  return `MB-${year}${month}${day}-${seqStr}${randomSuffix}`;
}

/**
 * Sinh cấu trúc chuỗi JSON lưu mã QR
 */
function generateQrData({ bookingCode, patientName, doctorName, specialtyName, workDate, timeSlot, queueNumber }) {
  return JSON.stringify({
    app: 'MEDBOOK',
    code: bookingCode,
    patient: patientName,
    doctor: doctorName,
    specialty: specialtyName,
    date: workDate,
    slot: timeSlot,
    stt: queueNumber,
    timestamp: new Date().toISOString()
  });
}

module.exports = {
  generateBookingCode,
  generateQrData
};

