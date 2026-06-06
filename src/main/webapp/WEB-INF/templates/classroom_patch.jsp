<%-- ═══════════════════════════════════════════════════════════════════════════
     PATCH 1: แสดงคะแนนใน "ประวัติการส่งการบ้าน" (ฝั่งนักเรียน)
     ค้นหาบรรทัดนี้ใน classroom.jsp แล้วแทนที่ทั้งบล็อก if/else if (REVIEWED)
     ═══════════════════════════════════════════════════════════════════════════

❌ โค้ดเดิม (ประมาณบรรทัด 561–568):

              <% if ("REVIEWED".equals(hw.getStatus()) && hw.getTeacherComment() != null && !hw.getTeacherComment().trim().isEmpty()) { %>
              <div style="margin-top:8px;padding:10px 12px;background:#f0fdf4;border-left:3px solid #16a34a;border-radius:0 8px 8px 0;">
                <div style="font-size:11px;font-weight:700;color:#15803d;margin-bottom:3px;">💬 Nhận xét của giảng viên</div>
                <div style="font-size:13px;color:#166534;line-height:1.5;"><%= hw.getTeacherComment() %></div>
              </div>
              <% } else if ("REVIEWED".equals(hw.getStatus())) { %>
              <div style="margin-top:6px;font-size:12px;color:#15803d;font-style:italic;">✓ Giảng viên đã chấm (không có nhận xét thêm)</div>
              <% } %>

✅ โค้ดใหม่ (แทนที่ด้วยบล็อกนี้):
--%>

              <% if ("REVIEWED".equals(hw.getStatus())) { %>
              <div style="margin-top:8px;padding:10px 12px;background:#f0fdf4;border-left:3px solid #16a34a;border-radius:0 8px 8px 0;">
                <%-- คะแนน --%>
                <% if (hw.isScored()) { %>
                <div style="display:flex;align-items:center;gap:8px;margin-bottom:6px;">
                  <span style="font-size:11px;font-weight:700;color:#15803d;">🏅 Điểm của bạn:</span>
                  <span style="font-size:18px;font-weight:800;color:#15803d;"><%= hw.getScore() %></span>
                  <span style="font-size:13px;color:#4ade80;">/ <%= hw.getMaxScore() %></span>
                  <%-- progress bar --%>
                  <div style="flex:1;background:#dcfce7;border-radius:99px;height:8px;overflow:hidden;min-width:60px;">
                    <div style="height:100%;background:#16a34a;border-radius:99px;width:<%= Math.round(hw.getScore() * 100.0 / hw.getMaxScore()) %>%;"></div>
                  </div>
                  <span style="font-size:11px;color:#15803d;"><%= Math.round(hw.getScore() * 100.0 / hw.getMaxScore()) %>%</span>
                </div>
                <% } %>
                <%-- ความคิดเห็น --%>
                <% if (hw.getTeacherComment() != null && !hw.getTeacherComment().trim().isEmpty()) { %>
                <div style="font-size:11px;font-weight:700;color:#15803d;margin-bottom:3px;">💬 Nhận xét của giảng viên</div>
                <div style="font-size:13px;color:#166534;line-height:1.5;"><%= hw.getTeacherComment() %></div>
                <% } else if (!hw.isScored()) { %>
                <div style="font-size:12px;color:#15803d;font-style:italic;">✓ Giảng viên đã chấm (không có nhận xét thêm)</div>
                <% } %>
              </div>
              <% } %>

<%-- ═══════════════════════════════════════════════════════════════════════════
     PATCH 2: แสดงคะแนนในตารางครู (คอลัมน์ "Trạng thái")
     ค้นหา: <th>Học viên</th><th>Tiêu đề</th><th>Nộp lúc</th><th>Trạng thái</th><th>Tệp</th><th>Quản lý</th>
     ═══════════════════════════════════════════════════════════════════════════

❌ โค้ดเดิม header ตาราง:
            <thead><tr><th>Học viên</th><th>Tiêu đề</th><th>Nộp lúc</th><th>Trạng thái</th><th>Tệp</th><th>Quản lý</th></tr></thead>

✅ โค้ดใหม่ — เพิ่มคอลัมน์ "Điểm":
--%>
            <thead><tr><th>Học viên</th><th>Tiêu đề</th><th>Nộp lúc</th><th>Trạng thái</th><th>Điểm</th><th>Tệp</th><th>Quản lý</th></tr></thead>

<%-- และใน tbody แต่ละ <tr> ให้เพิ่ม <td> คะแนนหลัง <td> Trạng thái:

❌ โค้ดเดิม (หลัง </td> ของ Trạng thái):
                <td>
                  <% if (hw.getFileName() != null && !hw.getFileName().isEmpty()) { %>

✅ เพิ่ม <td> คะแนนก่อน <td> Tệp:
--%>
                <td style="text-align:center;white-space:nowrap;">
                  <% if (hw.isScored()) { %>
                  <span style="font-weight:700;color:#15803d;font-size:14px;"><%= hw.getScore() %></span>
                  <span style="font-size:12px;color:#6b7280;">/ <%= hw.getMaxScore() %></span>
                  <% } else if ("REVIEWED".equals(hw.getStatus())) { %>
                  <span style="font-size:12px;color:#9ca3af;font-style:italic;">—</span>
                  <% } else { %>
                  <span style="font-size:12px;color:#d1d5db;">—</span>
                  <% } %>
                </td>

<%-- ═══════════════════════════════════════════════════════════════════════════
     PATCH 3: Modal ให้คะแนน (แทนที่ modal "Chấm bài tập" ทั้งก้อน)
     ค้นหา: <div class="overlay" id="mReviewHw">
     ═══════════════════════════════════════════════════════════════════════════

     แทนที่ทั้ง <div class="overlay" id="mReviewHw"> ... </div> ด้วย:
--%>

<div class="overlay" id="mReviewHw">
  <div class="modal" style="max-width:520px;">
    <div class="modal-head">
      <div class="modal-ico">📋</div>
      <div class="modal-title">Chấm bài tập &amp; Cho điểm</div>
    </div>
    <div class="review-hw-info">
      <div class="review-hw-name" id="reviewHwTitle">—</div>
      <div style="font-size:12px;color:var(--text3);margin-top:3px;">Học viên: <span id="reviewStudentName">—</span></div>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/homework">
      <input type="hidden" name="action"   value="markReviewed"/>
      <input type="hidden" name="courseId" value="<%= courseId %>"/>
      <input type="hidden" name="hwId"     id="reviewHwId"/>

      <%-- ── ส่วนคะแนน ── --%>
      <div class="form-group">
        <label class="form-label">🏅 Điểm <span style="font-weight:400;color:var(--text3);">(Không bắt buộc)</span></label>
        <div style="display:flex;align-items:center;gap:8px;">
          <input type="number" class="form-control" name="score" id="reviewScore"
                 min="0" max="100" placeholder="VD: 85"
                 style="width:90px;text-align:center;font-size:18px;font-weight:700;"
                 oninput="updateScoreBar()"/>
          <span style="font-size:16px;color:var(--text3);">/</span>
          <input type="number" class="form-control" name="maxScore" id="reviewMaxScore"
                 min="1" value="100" placeholder="100"
                 style="width:75px;text-align:center;"
                 oninput="updateScoreBar()"/>
          <span style="font-size:13px;color:var(--text3);">điểm</span>
        </div>
        <%-- progress bar preview --%>
        <div style="margin-top:8px;background:#f1f5f9;border-radius:99px;height:10px;overflow:hidden;">
          <div id="reviewScoreBar" style="height:100%;background:linear-gradient(90deg,#22c55e,#16a34a);border-radius:99px;width:0%;transition:width .3s;"></div>
        </div>
        <div id="reviewScoreLabel" style="font-size:12px;color:var(--text3);margin-top:3px;text-align:right;">—</div>
      </div>

      <%-- ── ส่วน Feedback ── --%>
      <div class="form-group">
        <label class="form-label">💬 Feedback từ giáo viên <span style="font-weight:400;color:var(--text3);">(Không bắt buộc)</span></label>
        <textarea class="form-control" name="teacherComment" id="reviewComment" rows="3"
          placeholder="Ví dụ: Làm tốt lắm! / Cần sửa chỗ này... / Đã đạt yêu cầu ✓"></textarea>
      </div>

      <div class="modal-foot">
        <button type="button" class="btn btn-ghost" onclick="closeModal('mReviewHw')">Hủy</button>
        <button type="submit" class="btn btn-primary">✓ Đã chấm xong</button>
      </div>
    </form>
  </div>
</div>

<%-- ═══════════════════════════════════════════════════════════════════════════
     PATCH 4: เพิ่ม JavaScript ลงใน classroom.js (หรือใน <script> ของ classroom.jsp)
     ─────────────────────────────────────────────────────────────────────────
     เพิ่มฟังก์ชัน updateScoreBar() และแก้ openReviewModal() ให้ reset ค่าคะแนน
     ═══════════════════════════════════════════════════════════════════════════ --%>
