function main(params) {
  const A = genMatrix();
  const B = genMatrix();
  const A_rows = A.length;
  const A_columns = A[0].length;
  const B_rows = B.length;
  const B_columns = B[0].length;

  let c = new Array(A_rows);

  for (let i = 0; i < A_rows; i++) {
    c[i] = new Array(B_rows);
    for (let j = 0; j < B_columns; j++) {
      c[i][j] = 0;
      for (let k = 0; k < A_columns; k++) {
        c[i][j] += (A[i][k] * B[k][j]);
      }
    }
  }

  return {
    "payload": c
  };
}

/**
 * Generates a random matrix with random values, minimum size of 50x50 and maximum size of 100x100.
 * 
 * @returns {number[][]} The generated matrix.
 */
function genMatrix() {
  let M = [];
  const rows = Math.floor(Math.random() * 51) + 50;
  const columns = Math.floor(Math.random() * 51) + 50;

  for (let i = 0; i < rows; i++) {
    M.push([]);
    for (let j = 0; j < columns; j++) {
      M[i].push(Math.random());
    }
  }
  return M;
}
